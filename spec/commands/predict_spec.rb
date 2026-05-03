# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Commands::Predict do
  include_context 'channel'

  let(:user) { Fabricate(:user, channel: channel, user_name: 'username') }
  let(:opponent) { Fabricate(:user, channel: channel) }

  it 'predicts 50% for equal elo players' do
    expect do
      expect(message: "@gamebot predict <@#{opponent.user_id}>", user: user, channel: channel).to respond_with_slack_message(
        "#{user.slack_mention} has a 50% chance of beating #{opponent.slack_mention}."
      )
    end.not_to change(Challenge, :count)
  end

  it 'predicts higher chance for player with higher elo' do
    user.update_attributes!(elo: 200)
    opponent.update_attributes!(elo: 0)
    expect do
      expect(message: "@gamebot predict <@#{opponent.user_id}>", user: user, channel: channel).to respond_with_slack_message(
        "#{user.slack_mention} has a 76% chance of beating #{opponent.slack_mention}."
      )
    end.not_to change(Challenge, :count)
  end

  it 'predicts lower chance for player with lower elo' do
    user.update_attributes!(elo: 0)
    opponent.update_attributes!(elo: 200)
    expect do
      expect(message: "@gamebot predict <@#{opponent.user_id}>", user: user, channel: channel).to respond_with_slack_message(
        "#{user.slack_mention} has a 24% chance of beating #{opponent.slack_mention}."
      )
    end.not_to change(Challenge, :count)
  end

  it 'predicts outcome for a doubles match' do
    opponent2 = Fabricate(:user, channel: channel)
    teammate = Fabricate(:user, channel: channel)
    expect do
      expect(message: "@gamebot predict #{opponent.slack_mention} #{opponent2.user_name} with #{teammate.user_name}", user: user, channel: channel).to respond_with_slack_message(
        "#{user.slack_mention} and #{teammate.slack_mention} has a 50% chance of beating #{opponent.slack_mention} and #{opponent2.slack_mention}."
      )
    end.not_to change(Challenge, :count)
  end

  context 'with against' do
    let(:player1) { Fabricate(:user, channel: channel, user_name: 'player1') }
    let(:player2) { Fabricate(:user, channel: channel, user_name: 'player2') }

    it 'predicts between two other players at equal elo' do
      expect do
        expect(message: "@gamebot predict #{player1.slack_mention} against #{player2.slack_mention}", user: user, channel: channel).to respond_with_slack_message(
          "#{player1.slack_mention} has a 50% chance of beating #{player2.slack_mention}."
        )
      end.not_to change(Challenge, :count)
    end

    it 'predicts between two other players with different elo' do
      player1.update_attributes!(elo: 200)
      player2.update_attributes!(elo: 0)
      expect do
        expect(message: "@gamebot predict #{player1.slack_mention} against #{player2.slack_mention}", user: user, channel: channel).to respond_with_slack_message(
          "#{player1.slack_mention} has a 76% chance of beating #{player2.slack_mention}."
        )
      end.not_to change(Challenge, :count)
    end

    it 'predicts between two teams' do
      player3 = Fabricate(:user, channel: channel, user_name: 'player3')
      player4 = Fabricate(:user, channel: channel, user_name: 'player4')
      expect do
        expect(message: "@gamebot predict #{player1.slack_mention} #{player2.user_name} against #{player3.user_name} #{player4.user_name}", user: user, channel: channel).to respond_with_slack_message(
          "#{player1.slack_mention} and #{player2.slack_mention} has a 50% chance of beating #{player3.slack_mention} and #{player4.slack_mention}."
        )
      end.not_to change(Challenge, :count)
    end

    it 'errors when no players on one side of against' do
      expect(message: "@gamebot predict against #{player2.slack_mention}", user: user, channel: channel).to respond_with_slack_message(
        'Please specify players on both sides of against.'
      )
    end
  end
end
