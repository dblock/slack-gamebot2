# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Commands::Games do
  include_context 'channel'

  let(:user) { Fabricate(:user, channel: channel, user_name: 'username') }
  let(:singles_challenge) { Fabricate(:challenge, channel: channel, challengers: [user]) }

  context 'without matches' do
    it 'displays no games' do
      expect(message: '<@bot_user_id> games', user: user, channel: channel).to respond_with_slack_message('No games have been played.')
    end
  end

  context 'with matches' do
    let(:opponent) { singles_challenge.challenged.first }
    let!(:match) { Fabricate(:match, channel: channel, challenge: singles_challenge) }

    it 'shows total games and per-player breakdown' do
      expect(message: '<@bot_user_id> games', user: user, channel: channel).to respond_with_slack_message([
        'A total of 2 games have been played.',
        "#{user.display_name}: 1 win, 0 losses",
        "#{opponent.display_name}: 0 wins, 1 loss"
      ].join("\n"))
    end

    it 'filters by player' do
      expect(message: "<@bot_user_id> games #{user.user_name}", user: user, channel: channel).to respond_with_slack_message([
        'A total of 1 game has been played.',
        "#{user.display_name}: 1 win, 0 losses"
      ].join("\n"))
    end

    context 'with a second match' do
      let(:singles_challenge2) { Fabricate(:challenge, channel: channel, challengers: [user]) }
      let!(:match2) { Fabricate(:match, channel: channel, challenge: singles_challenge2) }

      it 'shows total games sorted by most played' do
        expect(message: '<@bot_user_id> games', user: user, channel: channel).to respond_with_slack_message([
          'A total of 4 games have been played.',
          "#{user.display_name}: 2 wins, 0 losses",
          "#{opponent.display_name}: 0 wins, 1 loss",
          "#{singles_challenge2.challenged.first.display_name}: 0 wins, 1 loss"
        ].join("\n"))
      end
    end

    context 'with a single game' do
      let(:solo_challenge) { Fabricate(:challenge, channel: channel) }
      let!(:solo_match) { Fabricate(:match, channel: channel, challenge: solo_challenge) }

      it 'uses singular for 1 game total' do
        expect(message: "<@bot_user_id> games #{solo_match.winners.first.user_name}", user: user, channel: channel).to respond_with_slack_message([
          'A total of 1 game has been played.',
          "#{solo_match.winners.first.display_name}: 1 win, 0 losses"
        ].join("\n"))
      end
    end
  end

  context 'when filtering by a username that contains a command keyword' do
    let(:edmundo) { Fabricate(:user, channel: channel, user_name: 'edmundo') }
    let(:edmundo_challenge) { Fabricate(:challenge, channel: channel, challengers: [edmundo]) }
    let!(:edmundo_match) { Fabricate(:match, channel: channel, challenge: edmundo_challenge) }

    it 'does not trigger the undo command when the username contains "undo"' do
      expect(message: '<@bot_user_id> games edmundo', user: user, channel: channel).to respond_with_slack_message([
        'A total of 1 game has been played.',
        "#{edmundo.display_name}: 1 win, 0 losses"
      ].join("\n"))
    end
  end

  context 'when filtering by a username that is exactly a command keyword' do
    let(:undo_user) { Fabricate(:user, channel: channel, user_name: 'undo') }
    let(:undo_challenge) { Fabricate(:challenge, channel: channel, challengers: [undo_user]) }
    let!(:undo_match) { Fabricate(:match, channel: channel, challenge: undo_challenge) }

    it 'does not trigger the undo command when the username is "undo"' do
      expect(message: '<@bot_user_id> games undo', user: user, channel: channel).to respond_with_slack_message([
        'A total of 1 game has been played.',
        "#{undo_user.display_name}: 1 win, 0 losses"
      ].join("\n"))
    end
  end

  context 'with ties' do
    let(:draw_challenge) { Fabricate(:challenge, channel: channel, challengers: [user]) }
    let!(:draw_match) { Fabricate(:match, channel: channel, challenge: draw_challenge, tied: true) }

    it 'includes ties in the breakdown' do
      expect(message: "<@bot_user_id> games #{user.user_name}", user: user, channel: channel).to respond_with_slack_message([
        'A total of 1 game has been played.',
        "#{user.display_name}: 0 wins, 0 losses, 1 tie"
      ].join("\n"))
    end
  end
end
