# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Commands::Resigned do
  include_context 'channel'

  context 'with a challenge' do
    let(:challenged) { Fabricate(:user, channel: channel, user_name: 'username') }
    let!(:challenge) { Fabricate(:challenge, channel: channel, challenged: [challenged]) }

    before do
      challenge.accept!(challenged)
    end

    it 'resigned' do
      expect(message: '@gamebot resigned', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenge.challenged[0].display_name} (-48) resigned against #{challenge.challengers[0].display_name} (+48)."
      )
      challenge.reload
      expect(challenge.state).to eq ChallengeState::PLAYED
      expect(challenge.match.winners).to eq challenge.challengers
      expect(challenge.match.losers).to eq challenge.challenged
      expect(challenge.match.resigned?).to be true
    end

    context 'with channel leaderboard details' do
      before do
        channel.update_attributes!(details: [Details::LEADERBOARD])
      end

      it 'displays leaderboard in a thread' do
        expect(SecureRandom).to receive(:hex).and_return('thread_id')
        message_match_recorded = "Match has been recorded! #{challenge.challenged.map(&:display_name).and} resigned against #{challenge.challengers.map(&:display_name).and}."
        expect(message: '@gamebot resigned', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(message_match_recorded)
        calls = []
        expect(channel.slack_client).to have_received(:chat_postMessage).twice do |call|
          calls << call
        end
        expect(calls[0]).to eq({ channel: 'channel', text: message_match_recorded })
        expect(calls[1]).to eq({ channel: 'channel', text: channel.leaderboard_s, thread_ts: 'thread_id' })
      end
    end

    it 'resigned with score' do
      expect(message: '@gamebot resigned 15:21', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        'Cannot score when resigning.'
      )
    end
  end

  context 'resigned to' do
    let(:loser) { Fabricate(:user, channel: channel, user_name: 'username') }
    let(:winner) { Fabricate(:user, channel: channel) }

    it 'a player' do
      expect do
        expect do
          expect(message: "@gamebot resigned to #{winner.display_name}", user: loser.user_id, channel: channel).to respond_with_slack_message(
            "Match has been recorded! #{loser.user_name} (-48) resigned against #{winner.display_name} (+48)."
          )
        end.not_to change(Challenge, :count)
      end.to change(Match, :count).by(1)
      match = Match.asc(:_id).last
      expect(match.winners).to eq [winner]
      expect(match.losers).to eq [loser]
      expect(match.resigned?).to be true
    end

    it 'two players' do
      winner2 = Fabricate(:user, channel: channel)
      loser2 = Fabricate(:user, channel: channel)
      expect do
        expect do
          expect(message: "@gamebot resigned to #{winner.user_name} #{winner2.user_name} with #{loser2.user_name}", user: loser.user_id, channel: channel).to respond_with_slack_message(
            "Match has been recorded! #{loser.display_name} (-48) and #{loser2.display_name} (-48) resigned against #{winner.display_name} (+48) and #{winner2.display_name} (+48)."
          )
        end.not_to change(Challenge, :count)
      end.to change(Match, :count).by(1)
      match = Match.asc(:_id).last
      expect(match.winners).to eq [winner2, winner]
      expect(match.losers).to eq [loser2, loser]
      expect(match.resigned?).to be true
    end
  end
end
