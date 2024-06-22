require 'spec_helper'

describe SlackGamebot::Commands::Hi do
  let!(:team) { Fabricate(:team) }
  let(:client) { SlackGamebot::Web::Client.new(token: 'token', team: team) }

  it 'says hi' do
    expect(message: '@gamebot hi').to respond_with_slack_message('Hi <@user>!')
  end
end
