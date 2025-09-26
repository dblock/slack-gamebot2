# frozen_string_literal: true

class Season
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  belongs_to :team, index: true
  belongs_to :channel, index: true
  belongs_to :created_by, class_name: 'User', inverse_of: nil, index: true, optional: true
  has_many :challenges
  has_many :matches
  embeds_many :user_ranks

  after_create :archive_challenges!
  after_create :reset_users!

  validate :validate_challenges_and_matches
  validate :validate_channels
  validates_presence_of :channel
  validates_presence_of :team
  validate :validate_team

  SORT_ORDERS = ['created_at', '-created_at'].freeze

  def initialize(attrs = {})
    super
    create_user_ranks
  end

  def to_s
    [
      "#{label}: #{winners ? winners.map(&:to_s).and : 'n/a'}",
      "#{channel.matches.count} match#{'es' unless channel.matches.count == 1}",
      "#{players.count} player#{'s' unless players.count == 1}"
    ].join(', ')
  end

  def winners
    min = user_ranks.min(:rank)
    user_ranks.asc(:id).where(rank: min) if min
  end

  def players
    user_ranks.where(:rank.ne => nil)
  end

  private

  def validate_team
    return if team == channel.team

    errors.add(:team, 'Channel team must match.')
  end

  def validate_channels
    channels = [channel]
    channels.concat(challenges.map(&:channel))
    channels.uniq!
    errors.add(:channel, 'Season can only be recorded on one channel.') if channels.count != 1
  end

  def played_challenges
    persisted? ? challenges.played : channel.challenges.current.played
  end

  def label
    persisted? ? created_at.strftime('%F') : 'Current'
  end

  def validate_challenges_and_matches
    return if channel.matches.current.any? || channel.challenges.current.any?

    errors.add(:challenges, 'No matches have been recorded.')
  end

  def create_user_ranks
    return if user_ranks.any?

    channel.users.ranked.asc(:rank).asc(:_id).each do |user|
      user_ranks << UserRank.from_user(user)
    end
  end

  def archive_challenges!
    channel.challenges.where(
      :state.in => [
        ChallengeState::PROPOSED,
        ChallengeState::ACCEPTED,
        ChallengeState::DRAWN
      ]
    ).set(
      state: ChallengeState::CANCELED,
      updated_by_id: created_by&.id
    )
    channel.challenges.current.set(season_id: id)
    channel.matches.current.set(season_id: id)
  end

  def reset_users!
    User.reset_all!(channel)
  end
end
