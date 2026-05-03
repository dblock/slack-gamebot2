# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Commands::Games do
  include_context 'channel'

  let(:user) { Fabricate(:user, channel: channel, user_name: 'username') }
  let(:singles_challenge) { Fabricate(:challenge, channel: channel, challengers: [user]) }

  context 'without matches' do
    it 'displays no games' do
      expect(message: '@gamebot games', user: user, channel: channel).to respond_with_slack_message('No games have been played.')
    end
  end

  context 'with matches' do
    let(:opponent) { singles_challenge.challenged.first }
    let!(:match) { Fabricate(:match, channel: channel, challenge: singles_challenge) }

    it 'shows total games and per-player breakdown' do
      expect(message: '@gamebot games', user: user, channel: channel).to respond_with_slack_message([
        'A total of 2 games have been played.',
        "#{user.display_name}: 1 win, 0 losses",
        "#{opponent.display_name}: 0 wins, 1 loss"
      ].join("\n"))
    end

    it 'filters by player' do
      expect(message: "@gamebot games #{user.user_name}", user: user, channel: channel).to respond_with_slack_message([
        'A total of 1 game has been played.',
        "#{user.display_name}: 1 win, 0 losses"
      ].join("\n"))
    end

    context 'with a second match' do
      let(:singles_challenge2) { Fabricate(:challenge, channel: channel, challengers: [user]) }
      let!(:match2) { Fabricate(:match, channel: channel, challenge: singles_challenge2) }

      it 'shows total games sorted by most played' do
        expect(message: '@gamebot games', user: user, channel: channel).to respond_with_slack_message([
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
        expect(message: "@gamebot games #{solo_match.winners.first.user_name}", user: user, channel: channel).to respond_with_slack_message([
          'A total of 1 game has been played.',
          "#{solo_match.winners.first.display_name}: 1 win, 0 losses"
        ].join("\n"))
      end
    end
  end

  context 'with ties' do
    let(:draw_challenge) { Fabricate(:challenge, channel: channel, challengers: [user]) }
    let!(:draw_match) { Fabricate(:match, channel: channel, challenge: draw_challenge, tied: true) }

    it 'includes ties in the breakdown' do
      expect(message: "@gamebot games #{user.user_name}", user: user, channel: channel).to respond_with_slack_message([
        'A total of 1 game has been played.',
        "#{user.display_name}: 0 wins, 0 losses, 1 tie"
      ].join("\n"))
    end
  end
end
