# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Commands::Undo do
  include_context 'channel'

  let(:winner) { Fabricate(:user, channel: channel, user_name: 'winner') }
  let(:loser) { Fabricate(:user, channel: channel, user_name: 'loser') }

  context 'with a recent match' do
    let!(:match) { Fabricate(:match, channel: channel, winners: [winner], losers: [loser]) }

    it 'undoes the last match' do
      expect(message: '<@bot_user_id> undo', user: winner.user_id, channel: channel).to respond_with_slack_message(
        "Match #{match} has been undone."
      )
      expect(Match.where(id: match.id).first).to be_nil
    end

    it 'restores wins and losses' do
      expect do
        expect(message: '<@bot_user_id> undo', user: winner.user_id, channel: channel).to respond_with_slack_message(
          "Match #{match} has been undone."
        )
      end.to change { winner.reload.wins }.by(-1).and change { loser.reload.losses }.by(-1)
    end

    it 'restores elo' do
      winner_elo_before = winner.reload.elo
      loser_elo_before = loser.reload.elo
      expect(message: '<@bot_user_id> undo', user: winner.user_id, channel: channel).to respond_with_slack_message(
        "Match #{match} has been undone."
      )
      expect(winner.reload.elo).to be < winner_elo_before
      expect(loser.reload.elo).to be > loser_elo_before
    end

    it 'restores challenge state to accepted' do
      challenge = match.challenge
      expect(message: '<@bot_user_id> undo', user: winner.user_id, channel: channel).to respond_with_slack_message(
        "Match #{match} has been undone."
      )
      expect(challenge.reload.state).to eq ChallengeState::ACCEPTED
    end
  end

  context 'with a tie match' do
    let!(:match) { Fabricate(:match, channel: channel, winners: [winner], losers: [loser], tied: true) }

    it 'restores ties' do
      expect do
        expect(message: '<@bot_user_id> undo', user: winner.user_id, channel: channel).to respond_with_slack_message(
          "Match #{match} has been undone."
        )
      end.to change { winner.reload.ties }.by(-1).and change { loser.reload.ties }.by(-1)
    end
  end

  context 'with no recent match' do
    it 'errors' do
      expect(message: '<@bot_user_id> undo', user: winner.user_id, channel: channel).to respond_with_slack_message(
        'No match to undo.'
      )
    end
  end

  context 'with a match the user did not participate in' do
    let(:other_winner) { Fabricate(:user, channel: channel) }
    let(:other_loser) { Fabricate(:user, channel: channel) }
    let!(:match) { Fabricate(:match, channel: channel, winners: [other_winner], losers: [other_loser]) }

    it 'errors' do
      expect(message: '<@bot_user_id> undo', user: winner.user_id, channel: channel).to respond_with_slack_message(
        'No match to undo.'
      )
    end

    it 'allows a captain to undo' do
      winner.update_attributes!(captain: true)
      expect(message: '<@bot_user_id> undo', user: winner.user_id, channel: channel).to respond_with_slack_message(
        "Match #{match} has been undone."
      )
      expect(Match.where(id: match.id).first).to be_nil
    end
  end

  context 'with a match older than 1 hour' do
    let!(:match) { Fabricate(:match, channel: channel, winners: [winner], losers: [loser]) }

    before do
      match.update_attributes!(created_at: 2.hours.ago)
    end

    it 'errors' do
      expect(message: '<@bot_user_id> undo', user: winner.user_id, channel: channel).to respond_with_slack_message(
        'No match to undo.'
      )
    end
  end
end
