# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Commands::Sucks do
  include_context 'user'

  it 'sucks' do
    expect(message: '@gamebot sucks', user: user, channel: channel).to respond_with_slack_message(
      "No #{user.slack_mention}, you suck!"
    )
  end

  it 'suck' do
    expect(message: '@gamebot you suck', user: user, channel: channel).to respond_with_slack_message(
      "No #{user.slack_mention}, you suck!"
    )
  end

  it 'sucks!' do
    expect(message: '@gamebot sucks!', user: user, channel: channel).to respond_with_slack_message(
      "No #{user.slack_mention}, you suck!"
    )
  end

  it 'really sucks!' do
    expect(message: '@gamebot you suck!', user: user, channel: channel).to respond_with_slack_message(
      "No #{user.slack_mention}, you suck!"
    )
  end

  it 'does not conflict with a player name that contains suck' do
    expect(message: '@gamebot challenge suckarov', user: user, channel: channel).to respond_with_slack_message(
      "I don't know who suckarov is!"
    )
  end

  it 'sucks for someone with many losses' do
    allow_any_instance_of(User).to receive(:losses).and_return(6)
    expect(message: '@gamebot sucks', user: user, channel: channel).to respond_with_slack_message(
      "No #{user.slack_mention}, with 6 losses, you suck!"
    )
  end

  it 'sucks for a poorly ranked user' do
    allow_any_instance_of(User).to receive(:rank).and_return(4)
    expect(message: '@gamebot sucks', user: user, channel: channel).to respond_with_slack_message(
      "No #{user.slack_mention}, with a rank of 4, you suck!"
    )
  end
end
