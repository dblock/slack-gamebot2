require 'spec_helper'

describe SlackGamebot::Commands::Challenges do
  include_context 'channel'

  let(:user) { Fabricate(:user, user_name: 'username', channel: channel) }

  context 'with challenges' do
    let!(:challenge_proposed) { Fabricate(:challenge, channel: channel) }
    let!(:challenge_canceled) { Fabricate(:canceled_challenge, channel: channel) }
    let!(:challenge_declined) { Fabricate(:declined_challenge, channel: channel) }
    let!(:challenge_accepted) { Fabricate(:accepted_challenge, channel: channel) }
    let!(:challenge_played) { Fabricate(:played_challenge, channel: channel) }

    it 'displays a proposed and accepted challenges' do
      expect(message: '@gamebot challenges', user: user, channel: challenge_proposed.channel).to respond_with_slack_message(
        "a challenge between #{challenge_proposed.challengers.map(&:display_name).and} and #{challenge_proposed.challenged.map(&:display_name).and} was proposed just now\n" \
        "a challenge between #{challenge_accepted.challengers.map(&:display_name).and} and #{challenge_accepted.challenged.map(&:display_name).and} was accepted just now"
      )
    end
  end

  context 'without challenges' do
    it 'displays all challenges have been played' do
      expect(message: '@gamebot challenges', user: user, channel: channel).to respond_with_slack_message(
        'All the challenges have been played.'
      )
    end
  end
end
