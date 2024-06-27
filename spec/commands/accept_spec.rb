require 'spec_helper'

describe SlackGamebot::Commands::Accept do
  include_context 'channel'

  context 'regular challenge' do
    let(:challenged) { Fabricate(:user, channel: channel, user_name: 'username') }
    let!(:challenge) { Fabricate(:challenge, team: team, challenged: [challenged]) }

    it 'accepts a challenge' do
      expect(message: '@gamebot accept', user: challenged.user_id, channel: channel).to respond_with_slack_message(
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
      expect(message: '@gamebot accept', user: acceptor.user_id, channel: channel).to respond_with_slack_message(
        "#{acceptor.display_name} accepted #{challenge.challengers.map(&:display_name).and}'s challenge."
      )
      challenge.reload
      expect(challenge.state).to eq ChallengeState::ACCEPTED
      expect(challenge.challenged).to eq [acceptor]
    end

    it 'cannot accept an open challenge with themselves' do
      allow_any_instance_of(Slack::Web::Client).to receive(:users_info).and_return(nil)
      expect(message: '@gamebot accept', user: user.user_id, channel: channel).to respond_with_slack_message(
        "Player #{user.user_name} cannot play against themselves."
      )
      challenge.reload
      expect(challenge.state).to eq ChallengeState::PROPOSED
      expect(challenge.challenged).to eq [anyone_challenged]
    end
  end
end
