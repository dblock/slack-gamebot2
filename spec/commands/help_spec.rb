require 'spec_helper'

describe SlackGamebot::Commands::Help do
  let(:client) { SlackGamebot::Web::Client.new(token: 'token', team: team) }
  let(:message_hook) { SlackGamebot::Commands::Base }

  context 'subscribed team' do
    let!(:team) { Fabricate(:team, subscribed: true) }

    it 'help' do
      expect(client).to receive(:say).with(channel: 'channel', text: [SlackGamebot::Commands::Help::HELP].join("\n"))
      expect(client).to receive(:say).with(channel: 'channel', gif: 'help')
      message_hook.call(client, Hashie::Mash.new(channel: 'channel', text: '@gamebot help'))
    end
  end

  context 'non-subscribed team' do
    let!(:team) { Fabricate(:team) }

    it 'help' do
      expect(client).to receive(:say).with(channel: 'channel', text: [SlackGamebot::Commands::Help::HELP, team.trial_message].join("\n"))
      expect(client).to receive(:say).with(channel: 'channel', gif: 'help')
      message_hook.call(client, Hashie::Mash.new(channel: 'channel', text: '@gamebot help'))
    end
  end
end
