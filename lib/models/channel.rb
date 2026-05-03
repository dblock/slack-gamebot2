# frozen_string_literal: true

class Channel
  include Mongoid::Document
  include Mongoid::Timestamps

  field :channel_id, type: String
  field :inviter_id, type: String
  field :is_group, type: Boolean, default: false
  field :is_app_home, type: Boolean, default: false
  field :enabled, type: Boolean, default: true
  field :elo, type: Integer, default: 0
  field :elo_algorithm, type: String, default: 'adaptive'
  field :elo_k, type: Integer, default: Elo::Standard::DEFAULT_K
  field :elo_decay, type: Float, default: Elo::Adaptive::DELTA_TAU
  field :elo_glicko2_tau, type: Float, default: Elo::Glicko2::DEFAULT_TAU
  field :won, type: Boolean, default: true
  field :unbalanced, type: Boolean, default: false
  field :leaderboard_max, type: Integer
  field :gifs, type: Boolean, default: true
  field :aliases, type: Array, default: []

  field :expire, type: Integer, default: 8 * 60
  field :remind, type: Integer, default: 4 * 60

  field :details, type: Array, default: [Details::ELO]
  validates :details, inclusion: { in: Details.values }

  scope :api, -> { where(api: true) }
  scope :app_home, -> { where(is_app_home: true) }
  field :api, type: Boolean, default: false

  belongs_to :team
  validates_presence_of :team

  has_many :users, dependent: :destroy
  has_many :seasons, dependent: :destroy
  has_many :matches, dependent: :destroy
  has_many :challenges, dependent: :destroy

  index({ channel_id: 1, team_id: 1 }, unique: true)

  index({ enabled: 1 })
  scope :enabled, -> { where(enabled: true) }

  def api_url
    return unless api?

    "#{SlackRubyBotServer::Service.api_url}/channels/#{id}"
  end

  def aliases_s
    raise 'Bot aliases are not supported in private channels.' if is_group?

    aliases&.any? ? aliases.map { |a| "`#{a}`" }.and : 'not set'
  end

  def details_s
    details&.any? ? details.map { |a| "`#{a}`" }.and : 'not shown'
  end

  def elo_algorithm_s
    case elo_algorithm
    when 'standard' then "#{elo_algorithm} (k=#{elo_k})"
    when 'adaptive' then "#{elo_algorithm} (decay=#{elo_decay})"
    when 'glicko2'  then "#{elo_algorithm} (τ=#{elo_glicko2_tau})"
    else elo_algorithm
    end
  end

  def api_s
    api? ? 'on' : 'off'
  end

  def gifs_s
    gifs? ? 'on' : 'off'
  end

  def won_s
    won? ? 'on' : 'off'
  end

  def unbalanced_s
    unbalanced? ? 'on' : 'off'
  end

  def leaderboard_max_s
    leaderboard_max || 'not set'
  end

  def expire_s
    return 'never' unless expire

    ChronicDuration.output(expire * 60, format: :long)
  end

  def expire_message
    expire ? "Challenges expire after #{expire_s}." : 'Challenges never expire.'
  end

  def remind_s
    return 'never' unless remind

    ChronicDuration.output(remind * 60, format: :long)
  end

  def remind_message
    remind ? "Reminders will be sent after #{remind_s}." : 'Reminders are disabled.'
  end

  def expire_challenges!
    return unless expire

    challenges.proposed.where(:created_at.lt => Time.now.utc - expire.minutes).each do |challenge|
      challenge.expire!
      inform!("#{challenge} has expired.")
    end
  end

  def remind_challenges!
    return unless remind

    challenges.accepted.any_of(
      { :updated_at.lt => Time.now.utc - remind.minutes, :reminded_at.exists => false },
      { :reminded_at.lt => Time.now.utc - 24.hours }
    ).each do |challenge|
      challenge.remind!
    end
  end

  def leaderboard_s(max: nil, reverse: false)
    max ||= leaderboard_max
    ranked_players = users.ranked
    return nil if ranked_players.none?

    ranked_players = ranked_players.send(reverse ? :desc : :asc, :rank)
    ranked_players = ranked_players.limit(max) if max && max >= 1

    ranked_players.each_with_index.map do |user, index|
      "#{reverse ? index + 1 : user.rank}. #{user}"
    end.join("\n")
  end

  def slack_mention
    "<##{channel_id}>"
  end

  def self.slack_mention?(channel_name)
    slack_match = channel_name.match(/^<#(.*)\|(.*)>$/) || channel_name.match(/^<#(.*)>$/)
    slack_id = slack_match[1] if slack_match
    slack_id
  end

  def slack_client
    @slack_client ||= SlackGamebot::Web::Client.new(token: team.token, gifs: gifs)
  end

  def token
    team.token
  end

  def info
    slack_client.conversations_info(channel: channel_id)
  end

  def find_or_create_by_slack_id!(slack_id)
    instance = users.where(user_id: slack_id).first
    users_info = begin
      slack_client.users_info(user: slack_id)
    rescue Slack::Web::Api::Errors::SlackError => e
      raise e unless e.message == 'user_not_found'
    end
    instance_info = Hashie::Mash.new(users_info).user if users_info
    if users_info && instance
      if instance.user_name != instance_info.name || instance.is_admin != instance_info.is_admin || instance.is_owner != instance_info.is_owner
        instance.update_attributes!(
          user_name: instance_info.name,
          is_owner: instance_info.is_owner,
          is_admin: instance_info.is_admin
        )
      end
    elsif !instance && instance_info
      instance = users.create!(
        team: team,
        channel: self,
        user_id: slack_id,
        user_name: instance_info.name,
        registered: true,
        captain: captains.none?,
        is_owner: instance_info.is_owner,
        is_admin: instance_info.is_admin
      )
    end

    raise SlackGamebot::Error, "I don't know who <@#{slack_id}> is!" unless instance

    instance
  end

  def find_or_create_many_by_mention!(user_names)
    user_names.map { |user_name| find_or_create_by_mention!(user_name) }
  end

  def find_or_create_by_mention!(user_name)
    slack_id = User.slack_mention?(user_name)

    user = case slack_id
           when User::ANYONE
             users.where(user_id: User::ANYONE).first || User.create!(
               team: team,
               channel: self,
               user_id: User::ANYONE,
               user_name: User::ANYONE,
               nickname: 'anyone',
               registered: true
             )
           when nil
             users.where(user_name: ::Regexp.new("^#{Regexp.escape(user_name)}$", 'i')).first
           else
             users.where(user_id: slack_id).first || find_or_create_by_slack_id!(slack_id)
           end

    raise SlackGamebot::Error, "I know who #{user_name} is, but they are unregistered. Ask them to _register_." if user && !user.registered?
    raise SlackGamebot::Error, "I don't know who #{user_name} is!" unless user

    user
  end

  def captains
    users.captains
  end

  def channel_admins
    users
      .in(channel_id: id, user_id: [inviter_id, team.activated_user_id].uniq.compact)
      .or(channel_id: id, is_admin: true)
      .or(channel_id: id, is_owner: true)
  end

  def channel_admins_slack_mentions
    (["<@#{inviter_id}>"] + channel_admins.map(&:slack_mention)).uniq.or
  end

  def to_s
    "#{team}, channel_id=#{channel_id}"
  end

  def inform!(message)
    slack_client.chat_postMessage(text: message, channel: channel_id, as_user: true)
  end
end
