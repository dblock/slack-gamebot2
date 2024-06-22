require 'spec_helper'

describe SlackGamebot::Commands::Unknown, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:client) { SlackGamebot::Web::Client.new(token: 'token', team: team) }
  let(:message_hook) { SlackGamebot::Commands::Base }

  it 'invalid command' do
    expect(message: '@gamebot foobar').to respond_with_slack_message("Sorry <@user>, I don't understand that command!")
  end

  # it 'does not respond to sad face' do
  #   expect(SlackGamebot::Commands::Base).not_to receive(:chat_postMessage)
  #   message_hook.call(client, Hashie::Mash.new(text: ':((', channel: 'channel'))
  # end
end
