# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Commands::ChallengeQuestion do
  include_context 'channel'

  let(:user) { Fabricate(:user, channel: channel, user_name: 'username') }
  let(:opponent) { Fabricate(:user, channel: channel) }

  it 'displays elo at stake for a singles challenge' do
    expect do
      expect(message: "@gamebot challenge? <@#{opponent.user_id}>", user: user, channel: channel).to respond_with_slack_message(
        "#{user.slack_mention} challenging #{opponent.slack_mention} to a match is worth 48 elo."
      )
    end.not_to change(Challenge, :count)
  end

  it 'displays challenger elo first when stakes differ due to different tau values' do
    experienced_user = Fabricate(:user, channel: channel, user_name: 'veteran', tau: 5.0)
    fresh_opponent = Fabricate(:user, channel: channel)
    expect do
      expect(message: "@gamebot challenge? <@#{fresh_opponent.user_id}>", user: experienced_user, channel: channel).to respond_with_slack_message(
        "#{experienced_user.slack_mention} challenging #{fresh_opponent.slack_mention} to a match is worth 35 elo for #{experienced_user.slack_mention} and 48 elo for #{fresh_opponent.slack_mention}."
      )
    end.not_to change(Challenge, :count)
  end

  it 'displays elo at stake for a doubles challenge' do
    opponent2 = Fabricate(:user, channel: channel)
    teammate = Fabricate(:user, channel: channel)
    expect do
      expect(message: "@gamebot challenge? #{opponent.slack_mention} #{opponent2.user_name} with #{teammate.user_name}", user: user, channel: channel).to respond_with_slack_message(
        "#{user.slack_mention} and #{teammate.slack_mention} challenging #{opponent.slack_mention} and #{opponent2.slack_mention} to a match is worth 48 elo."
      )
    end.not_to change(Challenge, :count)
  end

  context 'with against' do
    let(:player1) { Fabricate(:user, channel: channel, user_name: 'player1') }
    let(:player2) { Fabricate(:user, channel: channel, user_name: 'player2') }

    it 'displays elo at stake between two other players' do
      expect do
        expect(message: "@gamebot challenge? #{player1.slack_mention} against #{player2.slack_mention}", user: user, channel: channel).to respond_with_slack_message(
          "#{player1.slack_mention} challenging #{player2.slack_mention} to a match is worth 48 elo."
        )
      end.not_to change(Challenge, :count)
    end

    it 'displays elo at stake between two other teams' do
      player3 = Fabricate(:user, channel: channel, user_name: 'player3')
      player4 = Fabricate(:user, channel: channel, user_name: 'player4')
      expect do
        expect(message: "@gamebot challenge? #{player1.slack_mention} #{player2.user_name} against #{player3.user_name} #{player4.user_name}", user: user, channel: channel).to respond_with_slack_message(
          "#{player1.slack_mention} and #{player2.slack_mention} challenging #{player3.slack_mention} and #{player4.slack_mention} to a match is worth 48 elo."
        )
      end.not_to change(Challenge, :count)
    end

    it 'errors when no players on one side of against' do
      expect(message: "@gamebot challenge? against #{player2.slack_mention}", user: user, channel: channel).to respond_with_slack_message(
        'Please specify players on both sides of against.'
      )
    end
  end

  context 'with unbalanced option enabled' do
    before do
      channel.update_attributes!(unbalanced: true)
    end

    it 'displays elo at stake with different number of opponents, challenger first' do
      opponent1 = Fabricate(:user, channel: channel)
      opponent2 = Fabricate(:user, channel: channel)
      expect do
        expect(message: "@gamebot challenge? #{opponent1.slack_mention} #{opponent2.slack_mention}", user: user, channel: channel).to respond_with_slack_message(
          "#{user.slack_mention} challenging #{opponent1.slack_mention} and #{opponent2.slack_mention} to a match is worth 48 elo for #{user.slack_mention} and 24 elo for #{opponent1.slack_mention} and #{opponent2.slack_mention}."
        )
      end.not_to change(Challenge, :count)
    end
  end
end
