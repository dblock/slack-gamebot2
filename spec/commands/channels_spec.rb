# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Commands::Channels do
  context 'DM' do
    include_context 'dm'

    let(:user_id) { 'U123' }

    context 'no channels' do
      it 'returns no channels with an invite hint' do
        expect(message: '<@bot_user_id> channels', channel: 'DM', user: user_id).to respond_with_slack_message(
          "No channels. To start a leaderboard, invite me to a channel with `/invite #{team.bot_mention}`."
        )
      end
    end

    context 'one channel with no matches, players or seasons' do
      let!(:game_channel) { Fabricate(:channel, team: team) }

      it 'shows the channel with zero stats' do
        expect(message: '<@bot_user_id> channels', channel: 'DM', user: user_id).to respond_with_slack_message(
          "#{game_channel.slack_mention}: 0 matches, 0 players, 0 seasons"
        )
      end
    end

    context 'one channel with one match' do
      let!(:game_channel) { Fabricate(:channel, team: team) }

      before { Fabricate(:match, channel: game_channel, team: team) }

      it 'shows match and player counts' do
        expect(message: '<@bot_user_id> channels', channel: 'DM', user: user_id).to respond_with_slack_message(
          "#{game_channel.slack_mention}: 1 match, 2 players, 0 seasons"
        )
      end
    end

    context 'two channels' do
      let!(:game_channel) { Fabricate(:channel, team: team) }
      let!(:second_channel) { Fabricate(:channel, team: team) }

      before do
        Array.new(2) { Fabricate(:match, channel: game_channel, team: team) }
        Fabricate(:match, channel: second_channel, team: team)
      end

      it 'lists both channels in creation order' do
        expect(message: '<@bot_user_id> channels', channel: 'DM', user: user_id).to respond_with_slack_message(
          "#{game_channel.slack_mention}: 2 matches, 4 players, 0 seasons\n" \
          "#{second_channel.slack_mention}: 1 match, 2 players, 0 seasons"
        )
      end
    end

    context 'one channel with a past season' do
      let!(:game_channel) { Fabricate(:channel, team: team) }

      before do
        Array.new(2) { Fabricate(:match, channel: game_channel, team: team) }
        Fabricate(:season, channel: game_channel, team: team)
      end

      it 'shows season count and only current season match count' do
        expect(message: '<@bot_user_id> channels', channel: 'DM', user: user_id).to respond_with_slack_message(
          "#{game_channel.slack_mention}: 0 matches, 0 players, 1 season"
        )
      end
    end

    context 'excludes disabled channels' do
      let!(:game_channel) { Fabricate(:channel, team: team) }
      let!(:disabled_channel) { Fabricate(:channel, team: team, enabled: false) }

      it 'does not show disabled channels' do
        expect(message: '<@bot_user_id> channels', channel: 'DM', user: user_id).to respond_with_slack_message(
          "#{game_channel.slack_mention}: 0 matches, 0 players, 0 seasons"
        )
      end
    end

    context 'excludes app home channels' do
      let!(:game_channel) { Fabricate(:channel, team: team) }
      let!(:app_home) { Fabricate(:channel, team: team, is_app_home: true) }

      it 'does not show app home channels' do
        expect(message: '<@bot_user_id> channels', channel: 'DM', user: user_id).to respond_with_slack_message(
          "#{game_channel.slack_mention}: 0 matches, 0 players, 0 seasons"
        )
      end
    end
  end

  context 'channel' do
    include_context 'user'

    it 'tells the user to run the command in a DM' do
      expect(message: '<@bot_user_id> channels', channel: channel.channel_id, user: user.user_id).to respond_with_slack_message(
        'Please run this command in a DM.'
      )
    end
  end
end
