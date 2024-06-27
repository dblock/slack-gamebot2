require 'spec_helper'

describe SlackGamebot::Commands::Register do
  include_context 'subscribed team'

  let!(:channel) { Fabricate(:channel, channel_id: 'channel', team: team) }
  let(:team2) { Fabricate(:team) }
  let(:channel2) { Fabricate(:channel, team: team2) }

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

  it 'registers a new user and promotes them to captain' do
    Fabricate(:user, team: team2, channel: channel2) # another user in another team
    allow_any_instance_of(User).to receive(:channel).and_return(channel)
    expect do
      expect(message: '@gamebot register', channel: channel, user: 'user').to respond_with_slack_message("Welcome <@user>! You're ready to play. You're also team captain.")
    end.to change(User, :count).by(1)
  end

  it 'registers a new user' do
    Fabricate(:user, team: team, channel: channel, registered: true, captain: false) # an existing user in the same team
    allow_any_instance_of(User).to receive(:channel).and_return(channel)
    expect do
      expect(message: '@gamebot register', channel: channel, user: 'user').to respond_with_slack_message("Welcome <@user>! You're ready to play. You're also team captain.")
    end.to change(User, :count).by(1)
  end

  it 'registers a new user' do
    Fabricate(:user, team: team, channel: channel, registered: true, captain: true) # an existing captain in the same team
    allow_any_instance_of(User).to receive(:channel).and_return(channel)
    expect do
      expect(message: '@gamebot register', channel: channel, user: 'user').to respond_with_slack_message("Welcome <@user>! You're ready to play.")
    end.to change(User, :count).by(1)
  end

  it 'registers an existing unregistered user' do
    user = Fabricate(:user, registered: false, captain: true, created_at: 2.days.ago)
    expect do
      expect(message: '@gamebot register', channel: channel, user: user).to respond_with_slack_message("Welcome back #{user.slack_mention}, I've updated your registration. You're also team captain.")
    end.not_to change(User, :count)
  end

  it 'notes an already registered users' do
    user = Fabricate(:user, registered: true, captain: true, updated_at: 2.days.ago, created_at: 2.days.ago, user_name: 'user_name', user_id: 'user_id')
    expect do
      expect(message: '@gamebot register', channel: channel, user: user).to respond_with_slack_message("Welcome back #{user.slack_mention}, you're already registered. You're also team captain.")
    end.not_to change(User, :count)
  end

  it 'registers a previously unregistered user but does not promote them to captain' do
    captain = Fabricate(:user, registered: true, captain: true)
    user = Fabricate(:user, registered: false, captain: false, created_at: 2.days.ago, user_name: 'user_name', user_id: 'user_id')
    expect do
      expect(message: '@gamebot register', channel: channel, user: user).to respond_with_slack_message("Welcome back #{user.slack_mention}, I've updated your registration.")
    end.not_to change(User, :count)
    expect(user.reload.registered?).to be true
    expect(user.reload.captain?).to be false
  end

  it 'registers a previously unregistered user and promotes them to captain' do
    user = Fabricate(:user, registered: false, captain: false, created_at: 2.days.ago)
    expect do
      expect(message: '@gamebot register', channel: channel, user: user).to respond_with_slack_message("Welcome back #{user.slack_mention}, I've updated your registration. You're also team captain.")
    end.not_to change(User, :count)
    expect(user.reload.registered?).to be true
    expect(user.reload.captain?).to be true
  end
end
