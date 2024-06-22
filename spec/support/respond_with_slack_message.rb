require 'rspec/expectations'

RSpec::Matchers.define :respond_with_slack_message do |expected|
  def parse(actual)
    actual = { message: actual } unless actual.is_a?(Hash)
    [actual[:channel] || 'channel', actual[:user] || 'user', actual[:message]]
  end

  match do |actual|
    client = respond_to?(:client) ? send(:client) : SlackGamebot::Web::Client.new(token: 'token')

    channel, user, message = parse(actual)

    allow(client).to receive(:say) do |options|
      @messages ||= []
      @messages.push options
    end

    SlackGamebot::Commands::Base.call(client, Hashie::Mash.new(text: message, channel: channel, user: user))

    matcher = have_received(:say).once
    matcher = matcher.with(hash_including(channel: channel, text: expected)) if channel && expected

    expect(client).to matcher

    true
  end

  failure_message do |_actual|
    message = "expected to receive message with text: #{expected} once,\n received:"
    message += @messages&.any? ? @messages.inspect : 'none'
    message
  end
end
