SlackRubyBotServer::Events.configure do |config|
  include SlackGamebot::Models::Mixins::Pluralize

  def parse_team_event(event)
    team = Team.where(team_id: event[:event][:team]).first || raise("Cannot find team with ID #{event[:event][:team]}.")
    data = Slack::Messages::Message.new(event[:event]).merge(team: team)
    return nil unless data.user == data.team.bot_user_id

    data
  end

  def parse_user_event(event)
    team = Team.where(team_id: event[:team_id]).first || raise("Cannot find team with ID #{event[:team_id]}.")
    Slack::Messages::Message.new(event[:event]).merge(team: team)
  end

  config.on :event, 'event_callback', 'member_joined_channel' do |event|
    data = parse_team_event(event)
    next { ok: false } unless data

    SlackGamebot::Api::Middleware.logger.info "#{data.team.name}: bot joined ##{data.channel}."
    channel = data.team.join_channel!(data.channel, data.inviter)

    text = [
      "Hi there! I'm your team's Leaderboard Gamebot. I don't know how to play any games myself, but I will keep a leaderboard for you in this channel.",
      'Start by challenging someone to a game with `@gamebot challenge @user`.',
      'Type `@gamebot help` for instructions and `@gamebot leaderboard` for current status.'
    ].join(' ')

    data.team.slack_client.chat_postMessage(channel: data.channel, text: text)

    { ok: true }
  end

  config.on :event, 'event_callback', 'member_left_channel' do |event|
    data = parse_team_event(event)
    next { ok: false } unless data

    SlackGamebot::Api::Middleware.logger.info "#{data.team.name}: bot left ##{data.channel}."
    data.team.leave_channel!(data.channel)

    { ok: true }
  end

  config.on :event, 'event_callback', 'app_home_opened' do |event|
    data = parse_user_event(event)
    next { ok: true } unless data && data.channel[0] == 'D'

    channel = data.team.channels.where(channel_id: data.channel).first
    next { ok: true } if channel

    channel = data.team.channels.create!(channel_id: data.channel, enabled: false, inviter_id: data.user)
    channel.users.create!(team: data.team, channel: channel, user_id: data.user, registered: false)

    text = [
      "Hi there! I'm your team's Leaderboard Gamebot. I don't know how to play any games myself, but I keep leaderboards for your team.",
      data.team.channels.enabled.count > 0 ? "I currenly keep leaderboards in #{pluralize(data.team.channels.enabled.count, 'channel')}#{' (' + data.team.channels.enabled.map(&:slack_mention).and + ')'}." : 'Invite me to a channel to start a new leaderboard.',
      'Type `@gamebot help` for more options.'
    ].join(' ')

    SlackGamebot::Api::Middleware.logger.info "#{data.team.name}: user opened bot home ##{data.channel}."
    data.team.slack_client.chat_postMessage(channel: data.channel, text: text)

    { ok: true }
  end
end