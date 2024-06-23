require 'spec_helper'

describe SlackGamebot::Commands::Decline do
  include_context 'channel'

  let(:challenged) { Fabricate(:user, user_name: 'username', channel: channel) }
  let!(:challenge) { Fabricate(:challenge, challenged: [challenged], channel: channel) }

  it 'declines a challenge' do
    expect(message: '@gamebot decline', user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
      "#{challenge.challenged.map(&:display_name).and} declined #{challenge.challengers.map(&:display_name).and} challenge."
    )
    expect(challenge.reload.state).to eq ChallengeState::DECLINED
  end
end
