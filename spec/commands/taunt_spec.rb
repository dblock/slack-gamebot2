require 'spec_helper'

describe SlackGamebot::Commands::Taunt, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:client) { SlackGamebot::Web::Client.new(token: 'token', team: team) }
  let(:user) { Fabricate(:user, user_name: 'username') }

  it 'taunts one person by user id' do
    victim = Fabricate(:user, team: team)
    expect(message: "@gamebot taunt <@#{victim.user_id}>", user: user.user_id).to respond_with_slack_message(
      "#{user.user_name} says that #{victim.user_name} sucks at this game!"
    )
  end

  it 'taunts one person by user name' do
    victim = Fabricate(:user, team: team)
    expect(message: "@gamebot taunt #{victim.user_name}", user: user.user_id).to respond_with_slack_message(
      "#{user.user_name} says that #{victim.user_name} sucks at this game!"
    )
  end

  it 'taunts multiple users by user id' do
    victim1 = Fabricate(:user, team: team)
    victim2 = Fabricate(:user, team: team)
    victim3 = Fabricate(:user, team: team)
    expect(message: "@gamebot taunt <@#{victim1.user_id}> <@#{victim2.user_id}> <@#{victim3.user_id}>", user: user.user_id).to respond_with_slack_message(
      "#{user.user_name} says that #{victim1.user_name}, #{victim2.user_name} and #{victim3.user_name} suck at this game!"
    )
  end

  it 'taunts multiple users by user name' do
    victim1 = Fabricate(:user, team: team)
    victim2 = Fabricate(:user, team: team)
    victim3 = Fabricate(:user, team: team)
    expect(message: "@gamebot taunt #{victim1.user_name} #{victim2.user_name} #{victim3.user_name}", user: user.user_id).to respond_with_slack_message(
      "#{user.user_name} says that #{victim1.user_name}, #{victim2.user_name} and #{victim3.user_name} suck at this game!"
    )
  end

  it 'no entered user to taunt' do
    expect(message: '@gamebot taunt', user: user.user_id).to respond_with_slack_message(
      'Please provide a user name to taunt.'
    )
  end
end
