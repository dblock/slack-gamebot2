# frozen_string_literal: true

class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :user_name, type: String
  field :wins, type: Integer, default: 0
  field :losses, type: Integer, default: 0
  field :losing_streak, type: Integer, default: 0
  field :winning_streak, type: Integer, default: 0
  field :ties, type: Integer, default: 0
  field :elo, type: Integer, default: 0
  field :elo_history, type: Array, default: []
  field :tau, type: Float, default: 0
  field :rank, type: Integer
  field :captain, type: Boolean, default: false
  field :registered, type: Boolean, default: true
  field :nickname, type: String
  field :is_admin, type: Boolean, default: false
  field :is_owner, type: Boolean, default: false

  belongs_to :team, index: true
  belongs_to :channel, index: true

  validates_presence_of :channel
  validates_presence_of :team
  validate :validate_team

  index({ user_id: 1, channel_id: 1 }, unique: true)
  index(user_name: 1, channel_id: 1)
  index(wins: 1, channel_id: 1)
  index(losses: 1, channel_id: 1)
  index(ties: 1, channel_id: 1)
  index(elo: 1, channel_id: 1)

  before_save :update_elo_history!
  after_save :rank!

  SORT_ORDERS = ['elo', '-elo', 'created_at', '-created_at', 'wins', '-wins', 'losses', '-losses', 'ties', '-ties', 'user_name', '-user_name', 'rank', '-rank'].freeze
  ANYONE = '*'
  EVERYONE = %w[here channel].freeze

  scope :ranked, -> { where(:rank.ne => nil) }
  scope :captains, -> { where(captain: true) }
  scope :everyone, -> { where(user_id: ANYONE) }

  def current_matches
    Match.current.where(channel: channel).any_of({ winner_ids: _id }, loser_ids: _id)
  end

  def slack_mention
    anyone? ? 'anyone' : "<@#{user_id}>"
  end

  def display_name
    registered ? nickname || user_name || slack_mention : '<unregistered>'
  end

  def anyone?
    user_id == ANYONE
  end

  def self.slack_mention?(user_name)
    slack_match = user_name.match(/^<[@!](.*)>$/)
    slack_id = slack_match[1] if slack_match
    slack_id = ANYONE if slack_id && EVERYONE.include?(slack_id)
    slack_id
  end

  def self.reset_all!(channel)
    User.where(channel: channel).set(
      wins: 0,
      losses: 0,
      ties: 0,
      elo: 0,
      elo_history: [],
      tau: 0,
      rank: nil,
      losing_streak: 0,
      winning_streak: 0
    )
  end

  def to_s
    wins_s = "#{wins} win#{'s' unless wins == 1}"
    losses_s = "#{losses} loss#{'es' unless losses == 1}"
    ties_s = "#{ties} tie#{'s' unless ties == 1}" if ties&.positive?
    elo_s = "elo: #{channel_elo}"
    lws_s = "lws: #{winning_streak}" if winning_streak >= losing_streak && winning_streak >= 3
    lls_s = "lls: #{losing_streak}" if losing_streak > winning_streak && losing_streak >= 3
    "#{display_name}: #{[wins_s, losses_s, ties_s].compact.join(', ')} (#{[elo_s, lws_s, lls_s].compact.join(', ')})"
  end

  def channel_elo
    elo + channel.elo
  end

  def promote!
    update_attributes!(captain: true)
  end

  def demote!
    update_attributes!(captain: false)
  end

  def register!
    return if registered?

    update_attributes!(registered: true)
    User.rank!(channel)
  end

  def unregister!
    return unless registered?

    update_attributes!(registered: false, rank: nil)
    User.rank!(channel)
  end

  def rank!
    return unless saved_change_to_elo?

    User.rank!(channel)
    reload.rank
  end

  def update_elo_history!
    return unless elo_changed?

    elo_history << elo
  end

  def self.rank!(channel)
    rank = 1
    players = any_of({ :wins.gt => 0 }, { :losses.gt => 0 }, :ties.gt => 0).where(channel: channel, registered: true).desc(:elo).desc(:wins).asc(:losses).desc(:ties)
    players.each_with_index do |player, index|
      if player.registered?
        rank += 1 if index.positive? && %i[elo wins losses ties].any? { |property| players[index - 1].send(property) != player.send(property) }
        player.set(rank: rank) unless rank == player.rank
      end
    end
  end

  def calculate_streaks!
    longest_winning_streak = 0
    longest_losing_streak = 0
    current_winning_streak = 0
    current_losing_streak = 0
    current_matches.asc(:_id).each do |match|
      if match.tied?
        current_winning_streak = 0
        current_losing_streak = 0
      elsif match.winner_ids.include?(_id)
        current_losing_streak = 0
        current_winning_streak += 1
      else
        current_winning_streak = 0
        current_losing_streak += 1
      end
      longest_losing_streak = current_losing_streak if current_losing_streak > longest_losing_streak
      longest_winning_streak = current_winning_streak if current_winning_streak > longest_winning_streak
    end
    return if losing_streak == longest_losing_streak && winning_streak == longest_winning_streak

    update_attributes!(losing_streak: longest_losing_streak, winning_streak: longest_winning_streak)
  end

  def self.rank_section(channel, users)
    ranks = users.map(&:rank)
    return users unless ranks.min && ranks.max

    where(channel: channel, :rank.gte => ranks.min, :rank.lte => ranks.max).asc(:rank).asc(:wins).asc(:ties)
  end

  private

  def validate_team
    return if team == channel.team

    errors.add(:team, 'Channel team must match.')
  end
end
