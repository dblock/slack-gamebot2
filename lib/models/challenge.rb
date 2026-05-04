# frozen_string_literal: true

class Challenge
  include Mongoid::Document
  include Mongoid::Timestamps

  index(state: 1, channel: 1)

  SORT_ORDERS = ['created_at', '-created_at', 'updated_at', '-updated_at', 'state', '-state', 'channel', '-channel'].freeze

  field :state, type: String, default: ChallengeState::PROPOSED
  field :reminded_at, type: DateTime

  belongs_to :team, index: true
  belongs_to :channel, index: true
  belongs_to :season, inverse_of: :challenges, index: true, optional: true
  belongs_to :created_by, class_name: 'User', inverse_of: nil, index: true, optional: true
  belongs_to :updated_by, class_name: 'User', inverse_of: nil, index: true, optional: true

  has_and_belongs_to_many :challengers, class_name: 'User', inverse_of: nil
  has_and_belongs_to_many :challenged, class_name: 'User', inverse_of: nil

  field :draw_scores, type: Array
  has_and_belongs_to_many :draw, class_name: 'User', inverse_of: nil

  has_one :match

  index({ challenger_ids: 1, state: 1 }, name: 'active_challenger_index')
  index({ challenged_ids: 1, state: 1 }, name: 'active_challenged_index')

  validate :validate_playing_against_themselves
  validate :validate_opponents_counts
  validate :validate_unique_challenge
  validate :validate_channels
  validate :validate_max_challenges_per_day, on: :create
  validate :validate_max_challenges_per_user, on: :create

  validates_presence_of :channel
  validates_presence_of :team
  validate :validate_team

  validate :validate_updated_by
  validate :validate_draw_scores
  validates_presence_of :updated_by, if: lambda { |challenge|
    ![ChallengeState::PROPOSED, ChallengeState::EXPIRED].include?(challenge.state)
  }
  validates_presence_of :channel

  # current challenges are not in an archived season
  scope :current, -> { where(season_id: nil) }

  # challenges scoped by state
  ChallengeState.each_value do |state|
    scope state.to_sym, -> { where(state: state) }
  end

  # Given a challenger and a list of names splits into two groups, returns users.
  def self.new_from_players_against(channel, names)
    idx = names.index('against')
    team1_names = idx ? names[0...idx] : []
    team2_names = idx ? names[(idx + 1)..] : []
    raise SlackGamebot::Error, 'Please specify players on both sides of against.' if team1_names.empty? || team2_names.empty?

    team1 = channel.find_or_create_many_by_mention!(team1_names)
    team2 = channel.find_or_create_many_by_mention!(team2_names)
    Challenge.new(
      team: channel.team,
      channel: channel,
      challengers: team1,
      challenged: team2,
      state: ChallengeState::PROPOSED
    )
  end

  def self.split_teammates_and_opponents(challenger, names, separator = 'with')
    channel = challenger.channel
    teammates = [challenger]
    opponents = []
    current_side = opponents

    names.each do |name|
      if name == separator
        current_side = teammates
      else
        current_side << channel.find_or_create_by_mention!(name)
      end
    end

    [teammates, opponents]
  end

  def self.new_from_teammates_and_opponents(challenger, names, separator = 'with')
    teammates, opponents = split_teammates_and_opponents(challenger, names, separator)
    Challenge.new(
      team: challenger.channel.team,
      channel: challenger.channel,
      created_by: challenger,
      challengers: teammates,
      challenged: opponents,
      state: ChallengeState::PROPOSED
    )
  end

  def self.create_from_teammates_and_opponents!(challenger, names, separator = 'with')
    new_from_teammates_and_opponents(challenger, names, separator).tap(&:save!)
  end

  def accept!(challenger)
    raise SlackGamebot::Error, "Challenge has already been #{state}." unless state == ChallengeState::PROPOSED

    if channel.max_challenges
      current = channel.challenges.where(state: ChallengeState::ACCEPTED).count
      if current >= channel.max_challenges
        raise SlackGamebot::Error, "Only #{channel.max_challenges} accepted challenge#{'s' unless channel.max_challenges == 1} allowed at a time, #{current} already in progress."
      end
    end

    updates = { updated_by: challenger, state: ChallengeState::ACCEPTED }
    updates[:challenged_ids] = [challenger._id] if open_challenge?
    update_attributes!(updates)
  end

  def decline!(challenger)
    raise SlackGamebot::Error, "Challenge has already been #{state}." unless state == ChallengeState::PROPOSED

    update_attributes!(updated_by: challenger, state: ChallengeState::DECLINED)
  end

  def cancel!(challenger)
    raise SlackGamebot::Error, "Challenge has already been #{state}." unless [ChallengeState::PROPOSED, ChallengeState::ACCEPTED].include?(state)

    update_attributes!(updated_by: challenger, state: ChallengeState::CANCELED)
  end

  def expire!
    raise SlackGamebot::Error, "Challenge has already been #{state}." unless state == ChallengeState::PROPOSED

    update_attributes!(state: ChallengeState::EXPIRED)
  end

  def remind!
    raise SlackGamebot::Error, "Challenge has already been #{state}." unless state == ChallengeState::ACCEPTED

    update_attributes!(reminded_at: Time.now.utc)
    players = (challengers + challenged).map(&:slack_mention).and
    channel.inform!("Hey #{players}, #{self} was accepted but never recorded. Please record the match result.")
  end

  def win!(winner, scores = nil)
    raise SlackGamebot::Error, 'Challenge must first be accepted.' if state == ChallengeState::PROPOSED
    raise SlackGamebot::Error, "Challenge has already been #{state}." unless state == ChallengeState::ACCEPTED

    winners, losers = winners_and_losers_for_win(winner)
    Match.lose!(team: channel.team, channel: channel, challenge: self, winners: winners, losers: losers, scores: scores)
    update_attributes!(state: ChallengeState::PLAYED)
  end

  def winners_and_losers_for_win(winner)
    if challengers.include?(winner)
      [challengers, challenged]
    elsif challenged.include?(winner)
      [challenged, challengers]
    else
      raise SlackGamebot::Error, "Only #{(challenged + challengers).map(&:user_name).or} can win this challenge."
    end
  end

  def lose!(loser, scores = nil)
    raise SlackGamebot::Error, 'Challenge must first be accepted.' if state == ChallengeState::PROPOSED
    raise SlackGamebot::Error, "Challenge has already been #{state}." unless state == ChallengeState::ACCEPTED

    winners, losers = winners_and_losers_for(loser)
    Match.lose!(team: channel.team, channel: channel, challenge: self, winners: winners, losers: losers, scores: scores)
    update_attributes!(state: ChallengeState::PLAYED)
  end

  def winners_and_losers_for(loser)
    if challenged.include?(loser)
      [challengers, challenged]
    elsif challengers.include?(loser)
      [challenged, challengers]
    else
      raise SlackGamebot::Error, "Only #{(challenged + challengers).map(&:user_name).or} can lose this challenge."
    end
  end

  def resign!(loser, scores = nil)
    raise SlackGamebot::Error, 'Challenge must first be accepted.' if state == ChallengeState::PROPOSED
    raise SlackGamebot::Error, "Challenge has already been #{state}." unless state == ChallengeState::ACCEPTED

    winners, losers = winners_and_losers_for_resigned(loser)
    Match.resign!(team: channel.team, channel: channel, challenge: self, winners: winners, losers: losers, scores: scores)
    update_attributes!(state: ChallengeState::PLAYED)
  end

  def winners_and_losers_for_resigned(loser)
    if challenged.include?(loser)
      [challengers, challenged]
    elsif challengers.include?(loser)
      [challenged, challengers]
    else
      raise SlackGamebot::Error, "Only #{(challenged + challengers).map(&:user_name).or} can resign this challenge."
    end
  end

  def draw!(player, scores = nil)
    raise SlackGamebot::Error, 'Challenge must first be accepted.' if state == ChallengeState::PROPOSED
    raise SlackGamebot::Error, "Challenge has already been #{state}." unless [ChallengeState::ACCEPTED, ChallengeState::DRAWN].include?(state)
    raise SlackGamebot::Error, "Already recorded a draw from #{player.user_name}." if draw.include?(player)

    draw << player
    update_attributes!(state: ChallengeState::DRAWN)
    update_attributes!(draw_scores: scores) if scores
    return if draw.count != (challenged.count + challengers.count)

    # in a draw, winners have a lower original elo
    winners, losers = winners_and_losers_for_draw(player)
    Match.draw!(team: channel.team, channel: channel, challenge: self, winners: winners, losers: losers, scores: scores)
    update_attributes!(state: ChallengeState::PLAYED)
  end

  def winners_and_losers_for_draw(player)
    raise SlackGamebot::Error, "Only #{(challenged + challengers).map(&:user_name).or} can draw this challenge." unless challenged.include?(player) || challengers.include?(player)

    if Elo.team_elo(challenged) < Elo.team_elo(challengers)
      [challenged, challengers]
    else
      [challengers, challenged]
    end
  end

  def to_s
    "a challenge between #{challengers.map(&:display_name).and} and #{challenged.map(&:display_name).and}"
  end

  def self.find_by_user(player, states = [ChallengeState::PROPOSED, ChallengeState::ACCEPTED])
    Challenge.any_of(
      { challenger_ids: player._id },
      challenged_ids: player._id
    ).where(
      channel: player.channel,
      :state.in => states
    ).first
  end

  def self.find_open_challenge(channel, states = [ChallengeState::PROPOSED])
    Challenge.where(
      channel: channel,
      challenged_ids: channel.users.everyone.map(&:_id),
      :state.in => states
    ).first
  end

  def open_challenge?
    challenged.any?(&:anyone?)
  end

  def draw_scores?
    draw_scores&.any?
  end

  private

  def validate_team
    return if team == channel.team

    errors.add(:team, 'Channel team must match.')
  end

  def validate_playing_against_themselves
    intersection = challengers & challenged
    errors.add(:challengers, "Player #{intersection.first.user_name} cannot play against themselves.") if intersection.any?
  end

  def validate_opponents_counts
    return if challengers.any? && challenged.any? && (challengers.count == challenged.count || channel.unbalanced)

    errors.add(:challenged, "Number of teammates (#{challengers.count}) and opponents (#{challenged.count}) must match.")
  end

  def validate_channels
    channels = [channel]
    channels.concat(challengers.map(&:channel))
    channels.concat(challenged.map(&:channel))
    channels << match.channel if match
    channels << season.channel if season
    channels.uniq!
    errors.add(:channel, 'Can only play others in the same channel.') if channels.count != 1
  end

  def validate_unique_challenge
    return unless [ChallengeState::PROPOSED, ChallengeState::ACCEPTED].include?(state)

    (challengers + challenged).each do |player|
      existing_challenge = ::Challenge.find_by_user(player)
      next unless existing_challenge.present?
      next if existing_challenge == self

      errors.add(:challenge, "#{player.user_name} can't play. There's already #{existing_challenge}.")
    end
  end

  def validate_updated_by
    case state
    when ChallengeState::ACCEPTED
      return if updated_by && challenged.include?(updated_by)

      errors.add(:accepted_by, "Only #{challenged.map(&:display_name).and} can accept this challenge.")
    when ChallengeState::DECLINED
      return if updated_by && challenged.include?(updated_by)

      errors.add(:declined_by, "Only #{challenged.map(&:display_name).and} can decline this challenge.")
    when ChallengeState::CANCELED
      return if updated_by && (challengers.include?(updated_by) || challenged.include?(updated_by))

      errors.add(:declined_by, "Only #{challengers.map(&:display_name).and} or #{challenged.map(&:display_name).and} can cancel this challenge.")
    end
  end

  def validate_draw_scores
    return unless draw_scores
    return if Score.tie?(draw_scores)

    errors.add(:scores, 'In a tie both sides must score the same number of points.')
  end

  def validate_max_challenges_per_day
    return unless channel&.max_challenges_per_day

    current = channel.challenges.where(:created_at.gte => channel.beginning_of_day).count
    return unless current >= channel.max_challenges_per_day

    errors.add(:challenge, "Only #{channel.max_challenges_per_day} challenge#{'s' unless channel.max_challenges_per_day == 1} allowed per day in this channel, #{current} already issued today.")
  end

  def validate_max_challenges_per_user
    return unless channel&.max_challenges_per_user
    return unless created_by

    current = channel.challenges.where(:created_at.gte => channel.beginning_of_day, :created_by_id => created_by._id).count
    return unless current >= channel.max_challenges_per_user

    errors.add(:challenge, "Only #{channel.max_challenges_per_user} challenge#{'s' unless channel.max_challenges_per_user == 1} allowed per day per user, #{current} already issued today.")
  end
end
