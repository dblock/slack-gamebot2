# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Commands::Draw do
  include_context 'channel'

  context 'with a challenge' do
    let(:challenged) { Fabricate(:user, user_name: 'username', channel: channel) }
    let!(:challenge) { Fabricate(:challenge, challenged: [challenged], channel: channel) }

    before do
      challenge.accept!(challenged)
    end

    it 'draw' do
      expect(message: '@gamebot draw', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match is a draw, waiting to hear from #{challenge.challengers[0].display_name}."
      )
      challenge.reload
      expect(challenge.state).to eq ChallengeState::DRAWN
      expect(challenge.draw).to eq challenge.challenged
    end

    it 'draw with a score' do
      expect(message: '@gamebot draw 2:2', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match is a draw, waiting to hear from #{challenge.challengers[0].display_name}. Recorded the score of 2:2."
      )
      challenge.reload
      expect(challenge.state).to eq ChallengeState::DRAWN
      expect(challenge.draw).to eq challenge.challenged
      expect(challenge.draw_scores?).to be true
      expect(challenge.draw_scores).to eq [[2, 2]]
    end

    context 'confirmation' do
      before do
        challenge.draw!(challenge.challengers.first)
      end

      it 'confirmed' do
        expect(message: '@gamebot draw', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
          "Match has been recorded! #{challenge.challengers[0].display_name} tied with #{challenge.challenged[0].display_name}."
        )
        challenge.reload
        expect(challenge.state).to eq ChallengeState::PLAYED
        expect(challenge.draw).to eq challenge.challenged + challenge.challengers
      end

      context 'with channel leaderboard details' do
        before do
          channel.update_attributes!(details: [Details::LEADERBOARD])
        end

        it 'displays leaderboard in a thread' do
          expect(SecureRandom).to receive(:hex).and_return('thread_id')
          message_match_recorded = "Match has been recorded! #{challenge.challengers[0].display_name} tied with #{challenge.challenged[0].display_name}."
          expect(message: '@gamebot draw', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(message_match_recorded)
          calls = []
          expect(channel.slack_client).to have_received(:chat_postMessage).twice do |call|
            calls << call
          end
          expect(calls[0]).to eq({ channel: 'channel', text: message_match_recorded })
          expect(calls[1]).to eq({ channel: 'channel', text: channel.leaderboard_s, thread_ts: 'thread_id' })
        end
      end

      it 'with score' do
        expect(message: '@gamebot draw 3:3', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
          "Match has been recorded! #{challenge.challengers[0].display_name} tied with #{challenge.challenged[0].display_name} with the score of 3:3."
        )
        challenge.reload
        expect(challenge.match.scores).to eq [[3, 3]]
      end

      it 'with invalid score' do
        expect(message: '@gamebot draw 21:15', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
          'In a tie both sides must score the same number of points.'
        )
      end

      it 'draw with scores' do
        expect(message: '@gamebot draw 21:15 15:21', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
          "Match has been recorded! #{challenge.challengers[0].display_name} tied with #{challenge.challenged[0].display_name} with the scores of 15:21 21:15."
        )
        challenge.reload
        expect(challenge.match.scores).to eq [[21, 15], [15, 21]]
      end
    end

    it 'draw already confirmed' do
      challenge.draw!(challenge.challenged.first)
      expect(message: '@gamebot draw', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match is a draw, still waiting to hear from #{challenge.challengers[0].display_name}."
      )
    end

    it 'does not update a previously lost match' do
      challenge.lose!(challenge.challenged.first)
      expect(message: '@gamebot draw', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        'No challenge to draw!'
      )
    end

    it 'does not update a previously won match' do
      challenge.lose!(challenge.challengers.first)
      expect(message: '@gamebot draw', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        'No challenge to draw!'
      )
    end
  end

  context 'without a challenge' do
    let(:winner) { Fabricate(:user) }
    let(:loser) { Fabricate(:user, user_name: 'username') }

    it 'draw to' do
      expect do
        expect do
          expect(message: "@gamebot draw to #{winner.user_name}", user: loser.user_id, channel: channel).to respond_with_slack_message(
            "Match is a draw, waiting to hear from #{winner.user_name}."
          )
        end.to change(Challenge, :count).by(1)
      end.not_to change(Match, :count)
      challenge = Challenge.desc(:_id).first
      expect(challenge.state).to eq ChallengeState::DRAWN
      expect(challenge.draw).to eq [loser]
    end

    it 'draw with a score' do
      expect do
        expect do
          expect(message: "@gamebot draw to #{winner.user_name} 2:2", user: loser.user_id, channel: channel).to respond_with_slack_message(
            "Match is a draw, waiting to hear from #{winner.user_name}. Recorded the score of 2:2."
          )
        end.to change(Challenge, :count).by(1)
      end.not_to change(Match, :count)
      challenge = Challenge.desc(:_id).first
      expect(challenge.state).to eq ChallengeState::DRAWN
      expect(challenge.draw).to eq [loser]
      expect(challenge.draw_scores?).to be true
      expect(challenge.draw_scores).to eq [[2, 2]]
    end

    context 'confirmation' do
      let!(:challenge) do
        Challenge.create!(
          team: loser.team,
          channel: channel,
          created_by: loser,
          updated_by: loser,
          challengers: [loser],
          challenged: [winner],
          draw: [loser],
          draw_scores: [],
          state: ChallengeState::DRAWN
        )
      end

      it 'still waiting' do
        expect(message: '@gamebot draw', user: loser.user_id, channel: channel).to respond_with_slack_message(
          "Match is a draw, still waiting to hear from #{winner.user_name}."
        )
      end

      it 'confirmed' do
        expect(message: '@gamebot draw', user: winner.user_id, channel: channel).to respond_with_slack_message(
          "Match has been recorded! #{loser.user_name} tied with #{winner.user_name}."
        )
        challenge.reload
        expect(challenge.state).to eq ChallengeState::PLAYED
        expect(challenge.draw).to eq [loser, winner]
      end

      it 'with score' do
        expect(message: '@gamebot draw 3:3', user: winner.user_id, channel: channel).to respond_with_slack_message(
          "Match has been recorded! #{loser.user_name} tied with #{winner.user_name} with the score of 3:3."
        )
        challenge.reload
        expect(challenge.match.scores).to eq [[3, 3]]
      end

      it 'with invalid score' do
        expect(message: '@gamebot draw 21:15', user: winner.user_id, channel: channel).to respond_with_slack_message(
          'In a tie both sides must score the same number of points.'
        )
      end

      it 'draw with scores' do
        expect(message: '@gamebot draw 21:15 15:21', user: winner.user_id, channel: challenge.channel).to respond_with_slack_message(
          "Match has been recorded! #{loser.user_name} tied with #{winner.user_name} with the scores of 15:21 21:15."
        )
        challenge.reload
        expect(challenge.match.scores).to eq [[21, 15], [15, 21]]
      end
    end
  end
end
