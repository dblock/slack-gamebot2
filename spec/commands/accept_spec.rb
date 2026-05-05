# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Commands::Accept do
  include_context 'channel'

  context 'regular challenge' do
    let(:challenged) { Fabricate(:user, channel: channel, user_name: 'username') }
    let!(:challenge) { Fabricate(:challenge, team: team, challenged: [challenged]) }

    it 'accepts a challenge' do
      expect(message: '<@bot_user_id> accept', user: challenged.user_id, channel: channel).to respond_with_slack_message(
        "#{challenge.challenged.map(&:display_name).and} accepted #{challenge.challengers.map(&:display_name).and}'s challenge."
      )
      expect(challenge.reload.state).to eq ChallengeState::ACCEPTED
    end
  end

  context 'open challenge' do
    let(:user) { Fabricate(:user, channel: channel) }
    let(:acceptor) { Fabricate(:user, channel: channel) }
    let(:anyone_challenged) { Fabricate(:user, channel: channel, user_id: User::ANYONE) }
    let!(:challenge) { Fabricate(:challenge, team: team, challengers: [user], challenged: [anyone_challenged]) }

    it 'accepts an open challenge' do
      allow_any_instance_of(Slack::Web::Client).to receive(:users_info).and_return(nil)
      expect(message: '<@bot_user_id> accept', user: acceptor.user_id, channel: channel).to respond_with_slack_message(
        "#{acceptor.display_name} accepted #{challenge.challengers.map(&:display_name).and}'s challenge."
      )
      challenge.reload
      expect(challenge.state).to eq ChallengeState::ACCEPTED
      expect(challenge.challenged).to eq [acceptor]
    end

    it 'cannot accept an open challenge with themselves' do
      allow_any_instance_of(Slack::Web::Client).to receive(:users_info).and_return(nil)
      expect(message: '<@bot_user_id> accept', user: user.user_id, channel: channel).to respond_with_slack_message(
        "Player #{user.user_name} cannot play against themselves."
      )
      challenge.reload
      expect(challenge.state).to eq ChallengeState::PROPOSED
      expect(challenge.challenged).to eq [anyone_challenged]
    end
  end

  context 'with max challenges set' do
    let(:challenged) { Fabricate(:user, channel: channel, user_name: 'username') }
    let(:other_challenger) { Fabricate(:user, channel: channel) }
    let(:other_challenged) { Fabricate(:user, channel: channel) }
    let!(:challenge) { Fabricate(:challenge, team: team, challenged: [challenged]) }

    before do
      channel.update_attributes!(max_challenges: 1)
      accepted = Fabricate(:challenge, team: team, challengers: [other_challenger], challenged: [other_challenged])
      accepted.accept!(other_challenged)
    end

    it 'cannot accept when at the limit' do
      expect(message: '<@bot_user_id> accept', user: challenged.user_id, channel: channel).to respond_with_slack_message(
        'Only 1 accepted challenge allowed at a time, 1 already in progress.'
      )
      expect(challenge.reload.state).to eq ChallengeState::PROPOSED
    end
  end

  context 'unregistered user' do
    let(:user) { Fabricate(:user, channel: channel) }

    before { user.unregister! }

    it 'cannot accept' do
      expect(message: '<@bot_user_id> accept', user: user.user_id, channel: channel).to respond_with_slack_message(
        "You're not registered. Type _register_ to register."
      )
    end
  end
end
