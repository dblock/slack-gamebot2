class Team
  field :dead_at, type: DateTime
  field :trial_informed_at, type: DateTime

  field :stripe_customer_id, type: String
  field :subscribed, type: Boolean, default: false
  field :subscribed_at, type: DateTime

  scope :api, -> { where(api: true) }
  field :api, type: Boolean, default: false
  field :api_token, type: String

  field :elo, type: Integer, default: 0
  field :unbalanced, type: Boolean, default: false
  field :leaderboard_max, type: Integer
  field :gifs, type: Boolean, default: true
  field :aliases, type: Array, default: %w[gamebot pongbot pp]

  scope :subscribed, -> { where(subscribed: true) }

  has_many :channels, dependent: :destroy
  has_many :admins, dependent: :destroy

  has_many :users
  has_many :seasons
  has_many :matches
  has_many :challenges

  before_save :update_subscribed_at
  after_update :subscribed!
  after_save :activated!

  def subscription_expired?
    return false if subscribed?

    time_limit = Time.now.utc - 2.weeks
    return false if created_at > time_limit

    true
  end

  def trial_ends_at
    raise 'Team is subscribed.' if subscribed?

    created_at + 2.weeks
  end

  def remaining_trial_days
    raise 'Team is subscribed.' if subscribed?

    [0, (trial_ends_at.to_date - Time.now.utc.to_date).to_i].max
  end

  def trial_message
    [
      if remaining_trial_days.zero?
        'Your trial subscription has expired.'
      else
        "Your trial subscription expires in #{remaining_trial_days} day#{remaining_trial_days == 1 ? '' : 's'}."
      end,
      subscribe_text
    ].join(' ')
  end

  def inform_trial!
    return if subscribed? || subscription_expired?
    return if trial_informed_at && (Time.now.utc < trial_informed_at + 7.days)

    inform! trial_message
    update_attributes!(trial_informed_at: Time.now.utc)
  end

  def subscribe_text
    "Subscribe your team for $49.99 a year at #{SlackRubyBotServer::Service.url}/subscribe?team_id=#{team_id}."
  end

  def update_cc_text
    "Update your credit card info at #{SlackRubyBotServer::Service.url}/update_cc?team_id=#{team_id}."
  end

  def to_s
    {
      name: name,
      domain: domain,
      id: team_id
    }.map do |k, v|
      "#{k}=#{v}" if v
    end.compact.join(', ')
  end

  def asleep?(dt = 2.weeks)
    time_limit = Time.now.utc - dt
    return false if created_at > time_limit

    recent_match = matches.desc(:updated_at).limit(1).first
    return false if recent_match && recent_match.updated_at >= time_limit

    recent_challenge = challenges.desc(:updated_at).limit(1).first
    return false if recent_challenge && recent_challenge.updated_at >= time_limit

    true
  end

  def dead?(dt = 1.month)
    asleep?(dt)
  end

  def dead!(message)
    inform! message
  ensure
    update_attributes!(dead_at: Time.now.utc)
  end

  def aliases_s
    aliases&.any? ? aliases.map { |a| "`#{a}`" }.and : 'not set'
  end

  def api_s
    api? ? 'on' : 'off'
  end

  def gifs_s
    gifs? ? 'on' : 'off'
  end

  def unbalanced_s
    unbalanced? ? 'on' : 'off'
  end

  def leaderboard_max_s
    leaderboard_max || 'not set'
  end

  def api_url
    return unless api?

    "#{SlackRubyBotServer::Service.api_url}/teams/#{id}"
  end

  def slack_client
    @slack_client ||= SlackGamebot::Web::Client.new(token: token, gifs: false)
  end

  def bot_mention
    "<@#{bot_user_id}>" if bot_user_id
  end

  def slack_channels
    raise 'missing bot_user_id' unless bot_user_id

    channels = []
    slack_client.users_conversations(
      user: bot_user_id,
      exclude_archived: true,
      types: 'public_channel,private_channel'
    ) do |response|
      channels.concat(response.channels)
    end
    channels
  end

  def inform!(message)
    slack_channels.each do |channel|
      logger.info "Sending '#{message}' to #{self} on ##{channel['name']}."
      slack_client.chat_postMessage(text: message, channel: channel['id'], as_user: true)
    end
  end

  def stripe_customer
    return unless stripe_customer_id

    @stripe_customer ||= Stripe::Customer.retrieve(stripe_customer_id)
  end

  def stripe_customer_text
    "Customer since #{Time.at(stripe_customer.created).strftime('%B %d, %Y')}."
  end

  def subscriber_text
    subscribed_at ? "Subscriber since #{subscribed_at.strftime('%B %d, %Y')}." : 'Team is subscribed.'
  end

  def stripe_subcriptions
    return unless stripe_customer

    stripe_customer.subscriptions
  end

  def stripe_customer_subscriptions_info(with_unsubscribe = false)
    stripe_customer.subscriptions.map do |subscription|
      amount = ActiveSupport::NumberHelper.number_to_currency(subscription.plan.amount.to_f / 100)
      current_period_end = Time.at(subscription.current_period_end).strftime('%B %d, %Y')
      if subscription.status == 'active'
        [
          "Subscribed to #{subscription.plan.name} (#{amount}), will#{subscription.cancel_at_period_end ? ' not' : ''} auto-renew on #{current_period_end}.",
          !subscription.cancel_at_period_end && with_unsubscribe ? "Send `unsubscribe #{subscription.id}` to unsubscribe." : nil
        ].compact.join("\n")
      else
        "#{subscription.status.titleize} subscription created #{Time.at(subscription.created).strftime('%B %d, %Y')} to #{subscription.plan.name} (#{amount})."
      end
    end
  end

  def stripe_customer_invoices_info
    stripe_customer.invoices.map do |invoice|
      amount = ActiveSupport::NumberHelper.number_to_currency(invoice.amount_due.to_f / 100)
      "Invoice for #{amount} on #{Time.at(invoice.date).strftime('%B %d, %Y')}, #{invoice.paid ? 'paid' : 'unpaid'}."
    end
  end

  def stripe_customer_sources_info
    stripe_customer.sources.map do |source|
      "On file #{source.brand} #{source.object}, #{source.name} ending with #{source.last4}, expires #{source.exp_month}/#{source.exp_year}."
    end
  end

  def active_stripe_subscription?
    !active_stripe_subscription.nil?
  end

  def active_stripe_subscription
    return unless stripe_customer

    stripe_customer.subscriptions.detect do |subscription|
      subscription.status == 'active' && !subscription.cancel_at_period_end
    end
  end

  def tags
    [
      subscribed? ? 'subscribed' : 'trial',
      stripe_customer_id? ? 'paid' : nil
    ].compact
  end

  def ping_if_active!
    return unless active?

    ping!
  rescue Slack::Web::Api::Errors::SlackError => e
    logger.warn "Active team #{self} ping, #{e.message}."
    case e.message
    when 'account_inactive', 'invalid_auth'
      deactivate!
    end
  end

  def find_create_or_updae_admin_by_slack_id!(slack_id)
    instance = admins.where(user_id: slack_id).first
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
      instance = admins.create!(
        team: self,
        user_id: slack_id,
        user_name: instance_info.name,
        is_owner: instance_info.is_owner,
        is_admin: instance_info.is_admin
      )
    end

    raise SlackGamebot::Error, "I don't know who <@#{slack_id}> is!" unless instance

    instance
  end

  def find_create_or_update_channel_by_channel_id!(channel_id, user_id)
    raise 'missing channel_id' unless channel_id
    return nil if channel_id[0] == 'D'

    channel = channels.where(channel_id: channel_id).first
    return channel if channel

    create_channel!(channel_id, user_id)
  end

  def find_create_or_update_user_in_channel_by_slack_id!(channel_id, user_id)
    channel = find_create_or_update_channel_by_channel_id!(channel_id, user_id)
    channel ? channel.find_or_create_by_slack_id!(user_id) : user_id
  end

  def join_channel!(channel_id, inviter_id)
    channel = channels.where(channel_id: channel_id).first
    if channel
      update_channel!(channel, inviter_id)
    else
      channel = create_channel!(channel_id, inviter_id)
    end
    channel
  end

  def leave_channel!(channel_id)
    channel = channels.where(channel_id: channel_id).first
    channel&.update_attributes!(enabled: false)
    channel || false
  end

  private

  INSTALLED_TEXT = [
    "Hi there! I'm your team's Leaderboard Gamebot.",
    "I don't play actual games, but I'll be keeping your leaderboards.",
    'Thanks for trying me out. To start, invite me to a channel.',
    'You can always DM me `help` for instructions.'
  ].join("\n")

  SUBSCRIBED_TEXT = [
    "Hi there! I'm your team's Leaderboard Gamebot.",
    "I don't play actual games, but I keep your leaderboards.",
    'Your team has purchased a yearly subscription.',
    'Follow us on X at https://twitter.com/playplayio for news and updates.',
    'Thanks for being a customer!'
  ].join("\n")

  def subscribed!
    return unless subscribed? && subscribed_changed?

    inform! SUBSCRIBED_TEXT
  end

  def activated!
    return unless active? && activated_user_id && bot_user_id
    return unless active_changed? || activated_user_id_changed?

    inform! INSTALLED_TEXT
  end

  def update_subscribed_at
    return unless subscribed_changed?

    if subscribed
      self.subscribed_at ||= Time.now.utc
    else
      self.subscribed_at = nil
    end
  end

  def update_channel!(channel, inviter_id)
    channel_info = slack_client.conversations_info(channel: channel.channel_id)
    logger.info "Updating channel id=#{channel.channel_id}, name=#{channel_info&.channel&.name}, #{self}."
    channel.update_attributes!(
      enabled: true,
      inviter_id: inviter_id,
      is_group: !!channel_info&.channel&.is_group
    )
  end

  def create_channel!(channel_id, inviter_id)
    # do not support direct message channels for all commands
    channel_info = slack_client.conversations_info(channel: channel_id)
    return nil if channel_info&.channel&.is_im

    logger.info "Creating channel id=#{channel_id}, name=#{channel_info&.channel&.name}, #{self}."

    channels.create!(
      channel_id: channel_id,
      enabled: true,
      inviter_id: inviter_id,
      is_group: !!channel_info&.channel&.is_group,
      elo: elo,
      aliases: channel_info&.channel&.is_group ? [] : aliases,
      gifs: gifs,
      unbalanced: unbalanced,
      leaderboard_max: leaderboard_max
    )
  end
end
