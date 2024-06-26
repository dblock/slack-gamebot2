class Channel
  include Mongoid::Document
  include Mongoid::Timestamps

  field :channel_id, type: String
  field :inviter_id, type: String
  field :enabled, type: Boolean, default: true
  field :elo, type: Integer, default: 0
  field :unbalanced, type: Boolean, default: false
  field :leaderboard_max, type: Integer
  field :gifs, type: Boolean, default: true
  field :aliases, type: Array, default: %w[pongbot]

  scope :api, -> { where(api: true) }
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
    aliases.map { |a| "`#{a}`" }.and if aliases&.any?
  end

  def api_s
    api? ? 'on' : 'off'
  end

  def slack_mention
    "<##{channel_id}>"
  end

  def slack_client
    team.slack_client
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
      team.slack_client.users_info(user: slack_id)
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
        captain: !captains.any?,
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
             users.where(user_name: ::Regexp.new("^#{user_name}$", 'i')).first
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
    team.slack_client.chat_postMessage(text: message, channel: channel_id, as_user: true)
  end
end
