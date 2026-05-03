# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Commands::Cancel do
  include_context 'channel'

  context 'challenger' do
    let(:challenger) { Fabricate(:user, channel: channel, user_name: 'username') }
    let!(:challenge) { Fabricate(:challenge, channel: channel, challengers: [challenger]) }

    it 'cancels a challenge' do
      expect(message: '@gamebot cancel', user: challenger.user_id, channel: challenge.channel).to respond_with_slack_message(
        "#{challenge.challengers.map(&:display_name).and} canceled a challenge against #{challenge.challenged.map(&:display_name).and}."
      )
      expect(challenge.reload.state).to eq ChallengeState::CANCELED
    end
  end

  context 'challenged' do
    let(:challenged) { Fabricate(:user, channel: channel, user_name: 'username') }
    let!(:challenge) { Fabricate(:challenge, channel: channel, challenged: [challenged]) }

    it 'cancels a challenge' do
      expect(message: '@gamebot cancel', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "#{challenge.challenged.map(&:display_name).and} canceled a challenge against #{challenge.challengers.map(&:display_name).and}."
      )
      expect(challenge.reload.state).to eq ChallengeState::CANCELED
    end
  end

  context 'unregistered user' do
    let(:user) { Fabricate(:user, channel: channel) }

    before { user.unregister! }

    it 'cannot cancel' do
      expect(message: '@gamebot cancel', user: user.user_id, channel: channel).to respond_with_slack_message(
        "You're not registered. Type _register_ to register."
      )
    end
  end
end
