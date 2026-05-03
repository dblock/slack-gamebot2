# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Commands::Won do
  include_context 'channel'

  context 'won disabled' do
    before do
      channel.update_attributes!(won: false)
    end

    it 'errors' do
      expect(message: '@gamebot won', user: Fabricate(:user, channel: channel).user_id, channel: channel).to respond_with_slack_message(
        "The won command is disabled for #{channel.slack_mention}."
      )
    end
  end

  context 'with an existing challenge' do
    let(:challenger) { Fabricate(:user, channel: channel) }
    let(:challenged_user) { Fabricate(:user, channel: channel, user_name: 'username') }
    let!(:challenge) { Fabricate(:challenge, channel: channel, challengers: [challenger], challenged: [challenged_user]) }

    before do
      challenge.accept!(challenged_user)
    end

    it 'won' do
      expect(message: '@gamebot won', user: challenger.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenger.display_name} (+48) defeated #{challenged_user.display_name} (-48)."
      )
      challenge.reload
      expect(challenge.state).to eq ChallengeState::PLAYED
      expect(challenge.match.winners).to eq [challenger]
      expect(challenge.match.losers).to eq [challenged_user]
      expect(challenger.reload.elo).to eq 48
      expect(challenger.reload.tau).to eq 0.5
      expect(challenged_user.reload.elo).to eq(-48)
      expect(challenged_user.reload.tau).to eq 0.5
    end

    it 'won against the challenger' do
      expect(message: "@gamebot won against #{challenger.user_name}", user: challenged_user.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenged_user.display_name} (+48) defeated #{challenger.display_name} (-48)."
      )
      challenge.reload
      expect(challenge.state).to eq ChallengeState::PLAYED
      expect(challenge.match.winners).to eq [challenged_user]
      expect(challenge.match.losers).to eq [challenger]
    end

    it 'won with score' do
      expect(message: '@gamebot won 21:15', user: challenger.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenger.display_name} (+56) defeated #{challenged_user.display_name} (-56) with the score of 21:15."
      )
      challenge.reload
      expect(challenge.match.scores).to eq [[15, 21]]
      expect(challenge.match.resigned?).to be false
    end

    it 'won with invalid score' do
      expect(message: '@gamebot won 15:21', user: challenger.user_id, channel: challenge.channel).to respond_with_slack_message(
        'Loser scores must come first.'
      )
    end

    it 'won with scores' do
      expect(message: '@gamebot won 21:15 14:21 11:5', user: challenger.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenger.display_name} (+51) defeated #{challenged_user.display_name} (-51) with the scores of 21:15 14:21 11:5."
      )
      challenge.reload
      expect(challenge.match.scores).to eq [[15, 21], [21, 14], [5, 11]]
    end

    it 'won with a crushing score' do
      expect(message: '@gamebot won 21:5', user: challenger.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenger.display_name} (+78) crushed #{challenged_user.display_name} (-78) with the score of 21:5."
      )
    end

    it 'won with a humiliating score' do
      expect(message: '@gamebot won 21:0', user: challenger.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenger.display_name} (+96) humiliated #{challenged_user.display_name} (-96) with the score of 21:0."
      )
    end

    it 'won in a close game' do
      expect(message: '@gamebot won 21:19', user: challenger.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenger.display_name} (+50) narrowly defeated #{challenged_user.display_name} (-50) with the score of 21:19."
      )
    end

    it 'won amending scores' do
      challenge.win!(challenger)
      expect(message: '@gamebot won 21:15 14:21 11:5', user: challenger.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match scores have been updated! #{challenger.display_name} (+48) defeated #{challenged_user.display_name} (-48) with the scores of 21:15 14:21 11:5."
      )
      challenge.reload
      expect(challenge.match.scores).to eq [[15, 21], [21, 14], [5, 11]]
    end

    it 'cannot win against yourself' do
      expect(message: "@gamebot won against #{challenger.user_name}", user: challenger.user_id, channel: challenge.channel).to respond_with_slack_message(
        'You cannot win against yourself!'
      )
    end
  end

  context 'won against' do
    let(:winner) { Fabricate(:user, channel: channel, user_name: 'username') }
    let(:loser) { Fabricate(:user, channel: channel) }

    it 'a player' do
      expect do
        expect do
          expect(message: "@gamebot won against #{loser.user_name}", user: winner, channel: channel).to respond_with_slack_message(
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
          expect(message: "@gamebot won against #{winner.user_name}", user: winner, channel: channel).to respond_with_slack_message(
            'You cannot win against yourself!'
          )
        end.not_to change(Challenge, :count)
      end.not_to change(Match, :count)
    end

    it 'two players' do
      loser2 = Fabricate(:user, channel: channel)
      winner2 = Fabricate(:user, channel: channel)
      expect do
        expect do
          expect(message: "@gamebot won against #{loser.user_name} #{loser2.user_name} with #{winner2.user_name}", user: winner, channel: channel).to respond_with_slack_message(
            "Match has been recorded! #{winner.user_name} (+48) and #{winner2.user_name} (+48) defeated #{loser.user_name} (-48) and #{loser2.user_name} (-48)."
          )
        end.not_to change(Challenge, :count)
      end.to change(Match, :count).by(1)
      match = Match.asc(:_id).last
      expect(match.winners).to eq [winner2, winner]
      expect(match.losers).to eq [loser2, loser]
    end

    it 'two players with scores' do
      loser2 = Fabricate(:user, channel: channel)
      winner2 = Fabricate(:user, channel: channel)
      expect do
        expect do
          expect(message: "@gamebot won against #{loser.user_name} #{loser2.user_name} with #{winner2.user_name} 21:15", user: winner, channel: channel).to respond_with_slack_message(
            "Match has been recorded! #{winner.user_name} (+56) and #{winner2.user_name} (+56) defeated #{loser.user_name} (-56) and #{loser2.user_name} (-56) with the score of 21:15."
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
          expect(message: "@gamebot won against #{loser.user_name} 21:15", user: winner, channel: channel).to respond_with_slack_message(
            "Match has been recorded! #{winner.user_name} (+56) defeated #{loser.user_name} (-56) with the score of 21:15."
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
          expect(message: "@gamebot won against #{loser.user_name} 21:15 14:21 11:5", user: winner, channel: channel).to respond_with_slack_message(
            "Match has been recorded! #{winner.user_name} (+51) defeated #{loser.user_name} (-51) with the scores of 21:15 14:21 11:5."
          )
        end.not_to change(Challenge, :count)
      end.to change(Match, :count).by(1)
      match = Match.asc(:_id).last
      expect(match.winners).to eq [winner]
      expect(match.losers).to eq [loser]
      expect(match.scores).to eq [[15, 21], [21, 14], [5, 11]]
      expect(match.resigned?).to be false
    end
  end

  context 'no challenge' do
    let(:user) { Fabricate(:user, channel: channel) }

    it 'errors' do
      expect(message: '@gamebot won', user: user.user_id, channel: channel).to respond_with_slack_message(
        'No challenge to win!'
      )
    end
  end
end
