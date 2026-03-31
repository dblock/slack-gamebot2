# frozen_string_literal: true

class Match
  include Mongoid::Document
  include Mongoid::Timestamps

  SORT_ORDERS = ['created_at', '-created_at'].freeze

  belongs_to :team, index: true
  belongs_to :channel, index: true
  field :tied, type: Boolean, default: false
  field :resigned, type: Boolean, default: false
  field :scores, type: Array
  belongs_to :challenge, index: true, optional: true
  belongs_to :season, inverse_of: :matches, index: true, optional: true
  before_create :calculate_elo!
  after_create :update_users!
  validate :validate_scores, unless: :tied?
  validate :validate_tied_scores, if: :tied?
  validate :validate_resigned_scores, if: :resigned?
  validate :validate_tied_resigned
  validate :validate_channels
  validates_presence_of :channel
  validates_presence_of :team
  validate :validate_team
  embeds_many :elo_changes

  has_and_belongs_to_many :winners, class_name: 'User', inverse_of: nil
  has_and_belongs_to_many :losers, class_name: 'User', inverse_of: nil

  # current matches are not in an archived season
  scope :current, -> { where(season_id: nil) }

  def scores?
    scores&.any?
  end

  def to_s
    if resigned?
      "#{display_names_with_details(losers)} resigned against #{display_names_with_details(winners)}"
    else
      [
        "#{display_names_with_details(winners)} #{score_verb} #{display_names_with_details(losers)}",
        scores ? "with #{Score.scores_to_string(scores)}" : nil
      ].compact.join(' ')
    end
  end

  def self.lose!(attrs)
    Match.create!(attrs)
  end

  def self.resign!(attrs)
    Match.create!(attrs.merge(resigned: true))
  end

  def self.draw!(attrs)
    Match.create!(attrs.merge(tied: true))
  end

  def update_users!
    if tied?
      winners.inc(ties: 1)
      losers.inc(ties: 1)
    else
      winners.inc(wins: 1)
      losers.inc(losses: 1)
    end
    winners.each(&:calculate_streaks!)
    losers.each(&:calculate_streaks!)
    User.rank!(channel)
  end

  def elo_s
    winners_delta, losers_delta = calculated_elo
    if (winners_delta | losers_delta).same?
      winners_delta.first.to_i.to_s
    elsif winners_delta.same? && losers_delta.same?
      [winners_delta.first, losers_delta.first].map(&:to_i).and
    else
      (winners_delta | losers_delta).map(&:to_i).and
    end
  end

  def winners_elo_s
    winners_delta, = calculated_elo
    winners_delta.same? ? winners_delta.first.to_i.to_s : winners_delta.map(&:to_i).and
  end

  def losers_elo_s
    _, losers_delta = calculated_elo
    losers_delta.same? ? losers_delta.first.to_i.to_s : losers_delta.map(&:to_i).and
  end

  private

  def display_names_with_details(users)
    if channel.details.include?(Details::ELO)
      users.map { |user| display_name_with_details(user) }.and
    else
      users.map(&:display_name).and
    end
  end

  def display_name_with_details(user)
    delta_s = elo_changes.detect { |elo_change| elo_change.user == user }&.to_s
    delta_s ? "#{user.display_name} (#{delta_s})" : user.display_name
  end

  def validate_team
    return if team == channel.team

    errors.add(:team, 'Channel team must match.')
  end

  def validate_channels
    channels = [channel]
    channels << challenge.channel if challenge
    channels.uniq!
    errors.add(:channel, 'Match can only be recorded on the same channel.') if channels.count != 1
  end

  def validate_scores
    return unless scores&.any?

    errors.add(:scores, 'Loser scores must come first.') unless Score.valid?(scores)
  end

  def validate_tied_scores
    return unless scores&.any?

    errors.add(:scores, 'In a tie both sides must have the same number of points.') unless Score.tie?(scores)
  end

  def validate_resigned_scores
    return unless scores&.any?

    errors.add(:scores, 'Cannot score when resigning.')
  end

  def validate_tied_resigned
    errors.add(:tied, 'Cannot be tied and resigned.') if tied? && resigned?
  end

  def score_verb
    if tied?
      'tied with'
    elsif !scores
      'defeated'
    else
      lose, win = Score.points(scores)
      ratio = lose.to_f / win
      if ratio > 0.9
        'narrowly defeated'
      elsif ratio > 0.4
        'defeated'
      else
        'crushed'
      end
    end
  end

  def score_ratio
    return 1.0 unless scores?

    loser_points, winner_points = Score.points(scores)
    total = loser_points + winner_points
    return 1.0 if total.zero?

    2.0 * winner_points / total
  end

  def calculated_elo
    @calculated_elo ||= begin
      algo = channel.elo_algorithm == 'standard' ? Elo::Standard : Elo::Adaptive
      winners_delta, losers_delta = algo.calculate(
        winners, losers,
        tied: tied?,
        score_ratio: score_ratio,
        k: channel.elo_k,
        decay: channel.elo_decay
      )

      winners.each_with_index do |winner, i|
        elo_changes << EloChange.new(match: self, user: winner, elo: winner.elo, delta: winners_delta[i])
        winner.elo += winners_delta[i]
      end

      losers.each_with_index do |loser, i|
        elo_changes << EloChange.new(match: self, user: loser, elo: loser.elo, delta: -losers_delta[i])
        loser.elo -= losers_delta[i]
      end

      [winners_delta, losers_delta]
    end
  end

  def calculate_elo!
    calculated_elo
    winners.each(&:save!)
    losers.each(&:save!)
  end
end
