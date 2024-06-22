require 'spec_helper'

describe SlackGamebot::Commands::Cancel, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:client) { SlackGamebot::Web::Client.new(token: 'token', team: team) }

  context 'challenger' do
    let(:challenger) { Fabricate(:user, user_name: 'username') }
    let!(:challenge) { Fabricate(:challenge, challengers: [challenger]) }

    it 'cancels a challenge' do
      expect(message: '@gamebot cancel', user: challenger.user_id, channel: challenge.channel).to respond_with_slack_message(
        "#{challenge.challengers.map(&:display_name).and} canceled a challenge against #{challenge.challenged.map(&:display_name).and}."
      )
      expect(challenge.reload.state).to eq ChallengeState::CANCELED
    end
  end

  context 'challenged' do
    let(:challenged) { Fabricate(:user, user_name: 'username') }
    let!(:challenge) { Fabricate(:challenge, challenged: [challenged]) }

    it 'cancels a challenge' do
      expect(message: '@gamebot cancel', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "#{challenge.challenged.map(&:display_name).and} canceled a challenge against #{challenge.challengers.map(&:display_name).and}."
      )
      expect(challenge.reload.state).to eq ChallengeState::CANCELED
    end
  end
end
