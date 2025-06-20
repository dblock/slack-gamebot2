# frozen_string_literal: true

RSpec.shared_context 'event' do
  include Rack::Test::Methods

  def app
    SlackRubyBotServer::Api::Middleware.instance
  end

  let(:team) { Fabricate(:team, bot_user_id: 'bot_user_id') }
  let(:event) { {} }
  let(:event_envelope) do
    {
      token: 'deprecated',
      api_app_id: 'A19GAJ72T',
      team_id: team.team_id,
      event: {
        message_ts: '1547842100.001400'
      }.merge(event),
      type: 'event_callback',
      event_id: 'EvFGTNRKLG',
      event_time: 1_547_842_101,
      authed_users: ['U04KB5WQR']
    }
  end

  before do
    allow_any_instance_of(Team).to receive(:inform!)
    allow_any_instance_of(Slack::Web::Client).to receive(:users_info)
    allow_any_instance_of(Slack::Events::Request).to receive(:verify!)
  end
end

RSpec::Matchers.define :respond_with_slack_message do |expected|
  def parse(actual)
    actual = { message: actual } unless actual.is_a?(Hash)
    attachments = actual[:attachments]
    attachments = [attachments] unless attachments.nil? || attachments.is_a?(Array)
    [actual[:channel] || 'channel', actual[:user] || 'user', actual[:message], attachments]
  end

  match do |actual|
    channel, user, message, attachments = parse(actual)

    allow(Team).to receive(:where).with(team_id: team.team_id).and_return([team])

    user_id = user.is_a?(User) ? user.user_id : user || 'user_id'
    channel_id = channel.is_a?(Channel) ? channel.channel_id : channel || 'channel_id'

    allow(team).to receive(:find_create_or_update_channel_by_channel_id!).with(channel_id, user_id).and_return(channel) if channel.is_a?(Channel)
    allow(team).to receive(:find_create_or_update_user_in_channel_by_slack_id!).with(channel_id, user_id).and_return(user) if user.is_a?(User)
    allow(user).to receive(:channel).and_return(channel) if user.is_a?(User) && channel.is_a?(Channel) && user.channel == channel

    slack_client = channel.is_a?(Channel) ? channel.slack_client : team.slack_client

    allow(slack_client).to receive(:chat_postMessage) do |options|
      @messages ||= []
      @messages.push options
    end.and_return('ts' => SecureRandom.hex)

    begin
      SlackRubyBotServer::Events.config.run_callbacks(
        :event,
        %w[event_callback app_mention],
        Slack::Messages::Message.new(
          'team_id' => team.team_id,
          'event' => {
            'user' => user_id,
            'channel' => channel_id,
            'text' => message,
            'attachments' => attachments
          }
        )
      )
    rescue Mongoid::Errors::Validations => e
      m = e.document.errors.messages.transform_values(&:uniq).values.join(', ')
      SlackGamebot::Api::Middleware.logger.warn(m)
      expect(m).to eq(expected)
      return true
    rescue StandardError => e
      SlackGamebot::Api::Middleware.logger.warn(e)
      expect(e.message).to eq(expected)
      return true
    end

    matcher = have_received(:chat_postMessage).once
    matcher = matcher.with(expected.is_a?(Hash) ? expected : hash_including(channel: channel_id, text: expected)) if channel && expected

    expect(slack_client).to matcher

    true
  end

  failure_message do |_actual|
    message = "expected to receive message with text: #{expected} once,\n received:"
    message += @messages&.any? ? @messages.inspect : 'none'
    message
  end
end
