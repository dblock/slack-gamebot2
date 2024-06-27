require 'spec_helper'

describe SlackGamebot::Commands::Taunt do
  include_context 'channel'

  let(:user) { Fabricate(:user, user_name: 'username') }

  it 'taunts one person by user id' do
    victim = Fabricate(:user, channel: channel)
    expect(message: "@gamebot taunt <@#{victim.user_id}>", user: user, channel: channel).to respond_with_slack_message(
      "#{user.user_name} says that #{victim.user_name} sucks at this game!"
    )
  end

  it 'taunts one person by user name' do
    victim = Fabricate(:user, channel: channel)
    expect(message: "@gamebot taunt #{victim.user_name}", user: user, channel: channel).to respond_with_slack_message(
      "#{user.user_name} says that #{victim.user_name} sucks at this game!"
    )
  end

  it 'taunts multiple users by user id' do
    victim1 = Fabricate(:user, channel: channel)
    victim2 = Fabricate(:user, channel: channel)
    victim3 = Fabricate(:user, channel: channel)
    expect(message: "@gamebot taunt <@#{victim1.user_id}> <@#{victim2.user_id}> <@#{victim3.user_id}>", user: user, channel: channel).to respond_with_slack_message(
      "#{user.user_name} says that #{victim1.user_name}, #{victim2.user_name} and #{victim3.user_name} suck at this game!"
    )
  end

  it 'taunts multiple users by user name' do
    victim1 = Fabricate(:user, channel: channel)
    victim2 = Fabricate(:user, channel: channel)
    victim3 = Fabricate(:user, channel: channel)
    expect(message: "@gamebot taunt #{victim1.user_name} #{victim2.user_name} #{victim3.user_name}", user: user, channel: channel).to respond_with_slack_message(
      "#{user.user_name} says that #{victim1.user_name}, #{victim2.user_name} and #{victim3.user_name} suck at this game!"
    )
  end

  it 'no entered user to taunt' do
    expect(message: '@gamebot taunt', user: user, channel: channel).to respond_with_slack_message(
      'Please provide a user name to taunt.'
    )
  end
end
