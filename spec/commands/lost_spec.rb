# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Commands::Lost do
  include_context 'channel'

  context 'with an existing challenge' do
    let(:challenged) { Fabricate(:user, channel: channel, user_name: 'username') }
    let!(:challenge) { Fabricate(:challenge, channel: channel, challenged: [challenged]) }

    before do
      challenge.accept!(challenged)
    end

    it 'lost' do
      expect(message: '@gamebot lost', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenge.challengers[0].display_name} (+48) defeated #{challenge.challenged[0].display_name} (-48)."
      )
      challenge.reload
      expect(challenge.state).to eq ChallengeState::PLAYED
      expect(challenge.match.winners).to eq challenge.challengers
      expect(challenge.match.losers).to eq challenge.challenged
      winner = challenge.match.winners.first
      loser = challenge.match.losers.first
      expect(winner.elo).to eq 48
      expect(winner.tau).to eq 0.5
      expect(loser.elo).to eq(-48)
      expect(loser.tau).to eq 0.5
    end

    context 'with channel leaderboard details' do
      before do
        channel.update_attributes!(details: [Details::LEADERBOARD])
      end

      it 'displays leaderboard in a thread' do
        expect(SecureRandom).to receive(:hex).and_return('thread_id')
        message_match_recorded = "Match has been recorded! #{challenge.challengers[0].display_name} defeated #{challenge.challenged[0].display_name}."
        expect(message: '@gamebot lost', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(message_match_recorded)
        calls = []
        expect(channel.slack_client).to have_received(:chat_postMessage).twice do |call|
          calls << call
        end
        expect(calls[0]).to eq({ channel: 'channel', text: message_match_recorded })
        expect(calls[1]).to eq({ channel: 'channel', text: channel.leaderboard_s, thread_ts: 'thread_id' })
      end
    end

    it 'updates existing challenge when lost to' do
      expect(message: "@gamebot lost to #{challenge.challengers.first.user_name}", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenge.challengers[0].display_name} (+48) defeated #{challenge.challenged[0].display_name} (-48)."
      )
      challenge.reload
      expect(challenge.state).to eq ChallengeState::PLAYED
      expect(challenge.match.winners).to eq challenge.challengers
      expect(challenge.match.losers).to eq challenge.challenged
    end

    it 'lost with score' do
      expect(message: '@gamebot lost 15:21', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenge.challengers[0].display_name} (+48) defeated #{challenge.challenged[0].display_name} (-48) with the score of 21:15."
      )
      challenge.reload
      expect(challenge.match.scores).to eq [[15, 21]]
      expect(challenge.match.resigned?).to be false
    end

    it 'lost with invalid score' do
      expect(message: '@gamebot lost 21:15', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        'Loser scores must come first.'
      )
    end

    it 'lost with scores' do
      expect(message: '@gamebot lost 21:15 14:21 5:11', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenge.challengers[0].display_name} (+48) defeated #{challenge.challenged[0].display_name} (-48) with the scores of 15:21 21:14 11:5."
      )
      challenge.reload
      expect(challenge.match.scores).to eq [[21, 15], [14, 21], [5, 11]]
    end

    it 'lost with a crushing score' do
      expect(message: '@gamebot lost 5:21', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenge.challengers[0].display_name} (+48) crushed #{challenge.challenged[0].display_name} (-48) with the score of 21:5."
      )
    end

    it 'lost in a close game' do
      expect(message: '@gamebot lost 19:21', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenge.challengers[0].display_name} (+48) narrowly defeated #{challenge.challenged[0].display_name} (-48) with the score of 21:19."
      )
    end

    it 'lost amending scores' do
      challenge.lose!(challenged)
      expect(message: '@gamebot lost 21:15 14:21 5:11', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match scores have been updated! #{challenge.challengers[0].display_name} (+48) defeated #{challenge.challenged[0].display_name} (-48) with the scores of 15:21 21:14 11:5."
      )
      challenge.reload
      expect(challenge.match.scores).to eq [[21, 15], [14, 21], [5, 11]]
    end

    it 'does not update a previously lost match' do
      challenge.lose!(challenged, [[11, 21]])
      challenge2 = Fabricate(:challenge, challenged: [challenged])
      challenge2.accept!(challenged)
      expect(message: '@gamebot lost', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenge2.challengers.map(&:display_name)[0]} (+41) defeated #{challenge2.challenged.map(&:display_name)[0]} (-40 → -88)."
      )
      challenge.reload
      expect(challenge.match.scores).to eq [[11, 21]]
      challenge2.reload
      expect(challenge2.state).to eq ChallengeState::PLAYED
      expect(challenge2.match.scores).to be_nil
    end

    it 'does not update a previously won match' do
      challenge.lose!(challenge.challengers.first, [[11, 21]])
      expect(message: '@gamebot lost', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        'No challenge to lose!'
      )
    end
  end

  context 'with an existing unbalanced challenge' do
    let(:challenged1) { Fabricate(:user, channel: channel, user_name: 'username') }
    let(:challenged2) { Fabricate(:user, channel: channel) }
    let(:challenge) { Fabricate(:challenge, channel: channel, challenged: [challenged1, challenged2]) }

    before do
      channel.update_attributes!(unbalanced: true)
      challenge.accept!(challenged1)
    end

    it 'lost' do
      expect(message: '@gamebot lost', user: challenged1.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenge.challengers[0].display_name} (+48) defeated #{challenge.challenged[0].display_name} (-24) and #{challenge.challenged.map(&:display_name)[1]} (-24)."
      )
      challenge.reload
      expect(challenge.state).to eq ChallengeState::PLAYED
      expect(challenge.match.winners).to eq challenge.challengers
      expect(challenge.match.losers).to eq challenge.challenged
      winner = challenge.match.winners.first
      loser = challenge.match.losers.first
      expect(winner.elo).to eq 48
      expect(winner.tau).to eq 0.5
      expect(loser.elo).to eq(-24)
      expect(loser.tau).to eq 0.5
    end
  end

  context 'lost to' do
    let(:loser) { Fabricate(:user, channel: channel, user_name: 'username') }
    let(:winner) { Fabricate(:user, channel: channel) }

    it 'a player' do
      expect do
        expect do
          expect(message: "@gamebot lost to #{winner.user_name}", user: loser, channel: channel).to respond_with_slack_message(
            "Match has been recorded! #{winner.user_name} (+48) defeated #{loser.user_name} (-48)."
          )
        end.not_to change(Challenge, :count)
      end.to change(Match, :count).by(1)
      match = Match.asc(:_id).last
      expect(match.winners).to eq [winner]
      expect(match.losers).to eq [loser]
    end

    it 'same player' do
      expect do
        expect do
          expect(message: "@gamebot lost to #{loser.user_name}", user: loser, channel: channel).to respond_with_slack_message(
            'You cannot lose to yourself!'
          )
        end.not_to change(Challenge, :count)
      end.not_to change(Match, :count)
    end

    it 'two players' do
      winner2 = Fabricate(:user, channel: channel)
      loser2 = Fabricate(:user, channel: channel)
      expect do
        expect do
          expect(message: "@gamebot lost to #{winner.user_name} #{winner2.user_name} with #{loser2.user_name}", user: loser, channel: channel).to respond_with_slack_message(
            "Match has been recorded! #{winner.user_name} (+48) and #{winner2.user_name} (+48) defeated #{loser.user_name} (-48) and #{loser2.user_name} (-48)."
          )
        end.not_to change(Challenge, :count)
      end.to change(Match, :count).by(1)
      match = Match.asc(:_id).last
      expect(match.winners).to eq [winner2, winner]
      expect(match.losers).to eq [loser2, loser]
    end

    it 'two players with scores' do
      winner2 = Fabricate(:user, channel: channel)
      loser2 = Fabricate(:user, channel: channel)
      expect do
        expect do
          expect(message: "@gamebot lost to #{winner.user_name} #{winner2.user_name} with #{loser2.user_name} 15:21", user: loser, channel: channel).to respond_with_slack_message(
            "Match has been recorded! #{winner.user_name} (+48) and #{winner2.user_name} (+48) defeated #{loser.user_name} (-48) and #{loser2.user_name} (-48) with the score of 21:15."
          )
        end.not_to change(Challenge, :count)
      end.to change(Match, :count).by(1)
      match = Match.asc(:_id).last
      expect(match.winners).to eq [winner2, winner]
      expect(match.losers).to eq [loser2, loser]
      expect(match.scores).to eq [[15, 21]]
    end

    it 'with score' do
      expect do
        expect do
          expect(message: "@gamebot lost to #{winner.user_name} 15:21", user: loser, channel: channel).to respond_with_slack_message(
            "Match has been recorded! #{winner.user_name} (+48) defeated #{loser.user_name} (-48) with the score of 21:15."
          )
        end.not_to change(Challenge, :count)
      end.to change(Match, :count).by(1)
      match = Match.asc(:_id).last
      expect(match.winners).to eq [winner]
      expect(match.losers).to eq [loser]
      expect(match.scores).to eq [[15, 21]]
      expect(match.resigned?).to be false
    end

    it 'with scores' do
      expect do
        expect do
          expect(message: "@gamebot lost to #{winner.user_name} 21:15 14:21 5:11", user: loser, channel: channel).to respond_with_slack_message(
            "Match has been recorded! #{winner.user_name} (+48) defeated #{loser.user_name} (-48) with the scores of 15:21 21:14 11:5."
          )
        end.not_to change(Challenge, :count)
      end.to change(Match, :count).by(1)
      match = Match.asc(:_id).last
      expect(match.winners).to eq [winner]
      expect(match.losers).to eq [loser]
      expect(match.scores).to eq [[21, 15], [14, 21], [5, 11]]
      expect(match.resigned?).to be false
    end
  end
end
