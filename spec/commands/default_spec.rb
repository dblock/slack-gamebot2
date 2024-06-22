require 'spec_helper'

describe SlackGamebot::Commands::Default do
  let!(:team) { Fabricate(:team) }
  let(:client) { SlackGamebot::Web::Client.new(token: 'token', team: team) }
  let(:message_hook) { SlackGamebot::Commands::Base }

  it 'default' do
    expect(client).to receive(:say).with(channel: 'channel', text: SlackGamebot::INFO)
    expect(client).to receive(:say).with(channel: 'channel', gif: 'robot')
    message_hook.call(client, Hashie::Mash.new(channel: 'channel', text: 'gamebpot'))
  end

  it 'upcase' do
    expect(client).to receive(:say).with(channel: 'channel', text: SlackGamebot::INFO)
    expect(client).to receive(:say).with(channel: 'channel', gif: 'robot')
    message_hook.call(client, Hashie::Mash.new(channel: 'channel', text: 'GAMEBOT'))
  end
end
