# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Commands::Unregister do
  include_context 'subscribed team'

  let!(:channel) { Fabricate(:channel, channel_id: 'channel', team: team) }
  let!(:user) { Fabricate(:user, channel: channel) }
  let(:another_user) { Fabricate(:user, captain: true, channel: channel) }
  let(:captain) { Fabricate(:user, captain: true, channel: channel) }

  before do
    allow_any_instance_of(Slack::Web::Client).to receive(:users_info).and_return(
      user: {
        id: 'user_id',
        name: 'user_name',
        is_admin: false,
        is_owner: false
      }
    )
  end

  it 'requires a captain to unregister someone' do
    expect(message: '@gamebot unregister someone', channel: channel, user: user).to respond_with_slack_message("You're not a captain, sorry.")
  end

  it 'registers, then unregisters a previously unknown user' do
    allow_any_instance_of(User).to receive(:channel).and_return(channel)
    expect do
      expect(message: '@gamebot unregister', channel: channel, user: 'user1').to respond_with_slack_message("I've removed <@user1> from the leaderboard.")
    end.to change(User, :count).by(1)
    expect(User.where(channel: channel, user_id: 'user1').first.registered).to be false
  end

  it 'unregisters self' do
    expect(message: '@gamebot unregister', user: user, channel: channel).to respond_with_slack_message("I've removed #{user.slack_mention} from the leaderboard.")
    expect(user.reload.registered).to be false
  end

  it 'unregisters self via me' do
    expect(message: '@gamebot unregister me', user: user, channel: channel).to respond_with_slack_message("I've removed #{user.slack_mention} from the leaderboard.")
    expect(user.reload.registered).to be false
  end

  it 'unregisters another user' do
    expect(message: "@gamebot unregister #{another_user.user_name}", user: captain, channel: channel).to respond_with_slack_message("I've removed #{another_user.slack_mention} from the leaderboard.")
    expect(another_user.reload.registered).to be false
  end

  it 'unregisters multiple users' do
    user1 = Fabricate(:user, channel: channel)
    user2 = Fabricate(:user, channel: channel)
    expect(message: "@gamebot unregister #{user1.user_name} <@#{user2.user_id}>", user: captain, channel: channel).to respond_with_slack_message(
      "I've removed <@#{user1.user_id}> and <@#{user2.user_id}> from the leaderboard."
    )
    expect(user1.reload.registered).to be false
    expect(user2.reload.registered).to be false
  end

  context 'with another team' do
    let(:team2) { Fabricate(:team) }
    let(:channel2) { Fabricate(:channel, team: team2) }
    let(:user2) { Fabricate(:user, team: team2, channel: channel2) }

    it 'cannot unregister an unknown user by name' do
      expect(message: "@gamebot unregister #{user2.user_name}", user: captain, channel: channel).to respond_with_slack_message("I don't know who #{user2.user_name} is!")
    end
  end
end
