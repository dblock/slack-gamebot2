require 'spec_helper'

describe SlackGamebot::Commands::Info do
  let(:client) { SlackGamebot::Web::Client.new(token: 'token', team: team) }
  let(:message_hook) { SlackGamebot::Commands::Base }
  let(:team) { Fabricate(:team) }

  it 'info' do
    expect(client).to receive(:say).with(channel: 'channel', text: SlackGamebot::INFO)
    message_hook.call(client, Hashie::Mash.new(channel: 'channel', text: '@gamebot info'))
  end
end
