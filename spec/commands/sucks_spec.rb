require 'spec_helper'

describe SlackGamebot::Commands::Sucks, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:user) { Fabricate(:user) }
  let(:client) { SlackGamebot::Web::Client.new(token: 'token', team: team) }

  it 'sucks' do
    expect(message: '@gamebot sucks').to respond_with_slack_message(
      'No <@user>, you suck!'
    )
  end

  it 'suck' do
    expect(message: '@gamebot you suck').to respond_with_slack_message(
      'No <@user>, you suck!'
    )
  end

  it 'sucks!' do
    expect(message: '@gamebot sucks!').to respond_with_slack_message(
      'No <@user>, you suck!'
    )
  end

  it 'really sucks!' do
    expect(message: '@gamebot you suck!').to respond_with_slack_message(
      'No <@user>, you suck!'
    )
  end

  it 'does not conflict with a player name that contains suck' do
    allow(client).to receive(:users_info)
    expect(message: '@gamebot challenge suckarov', user: user.user_id, channel: 'pongbot').to respond_with_slack_message(
      "I don't know who suckarov is! Ask them to _register_."
    )
  end

  it 'sucks for someone with many losses' do
    allow_any_instance_of(User).to receive(:losses).and_return(6)
    expect(message: '@gamebot sucks').to respond_with_slack_message(
      'No <@user>, with 6 losses, you suck!'
    )
  end

  it 'sucks for a poorly ranked user' do
    allow_any_instance_of(User).to receive(:rank).and_return(4)
    expect(message: '@gamebot sucks').to respond_with_slack_message(
      'No <@user>, with a rank of 4, you suck!'
    )
  end
end
