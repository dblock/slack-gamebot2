require 'spec_helper'

describe SlackGamebot::Commands::Demote do
  include_context 'channel'

  context 'captain' do
    let(:user) { Fabricate(:user, channel: channel, user_name: 'username', captain: true) }

    it 'demotes self' do
      another_user = Fabricate(:user, channel: channel, captain: true)
      expect(message: '@gamebot demote me', user: user.user_id, channel: channel).to respond_with_slack_message(
        "#{user.user_name} is no longer captain."
      )
      expect(another_user.reload.captain?).to be true
    end

    it 'cannot demote the last captain' do
      expect(message: '@gamebot demote me', user: user.user_id, channel: channel).to respond_with_slack_message(
        "You cannot demote yourself, you're the last captain. Promote someone else first."
      )
    end

    it 'cannot demote another captain' do
      another_user = Fabricate(:user, channel: channel, captain: true)
      expect(message: "@gamebot demote #{another_user.user_name}", user: user.user_id, channel: channel).to respond_with_slack_message(
        'You can only demote yourself, try _demote me_.'
      )
      expect(another_user.reload.captain?).to be true
    end
  end

  context 'not captain' do
    let!(:captain) { Fabricate(:user, channel: channel, captain: true) }
    let(:user) { Fabricate(:user, channel: channel, user_name: 'username') }

    it 'cannot demote' do
      expect(message: '@gamebot demote me', user: user.user_id, channel: channel).to respond_with_slack_message(
        "You're not a captain, sorry."
      )
      expect(user.reload.captain?).to be false
    end
  end
end
