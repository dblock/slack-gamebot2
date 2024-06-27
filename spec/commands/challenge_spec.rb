require 'spec_helper'

describe SlackGamebot::Commands::Challenge do
  include_context 'channel'

  let(:user) { Fabricate(:user, channel: channel, user_name: 'username') }
  let(:opponent) { Fabricate(:user, channel: channel) }

  it 'creates a singles challenge by user id' do
    expect do
      expect(message: "@gamebot challenge <@#{opponent.user_id}>", user: user, channel: channel).to respond_with_slack_message(
        "#{user.slack_mention} challenged #{opponent.slack_mention} to a match!"
      )
    end.to change(Challenge, :count).by(1)
    challenge = Challenge.last
    expect(challenge.channel).to eq channel
    expect(challenge.created_by).to eq user
    expect(challenge.challengers).to eq [user]
    expect(challenge.challenged).to eq [opponent]
  end

  it 'creates a singles challenge by user name' do
    expect do
      expect(message: "@gamebot challenge #{opponent.slack_mention}", user: user, channel: channel).to respond_with_slack_message(
        "#{user.slack_mention} challenged #{opponent.slack_mention} to a match!"
      )
    end.to change(Challenge, :count).by(1)
  end

  it 'creates a doubles challenge by user name' do
    opponent2 = Fabricate(:user, channel: channel)
    teammate = Fabricate(:user, channel: channel)
    expect do
      expect(message: "@gamebot challenge #{opponent.slack_mention} #{opponent2.user_name} with #{teammate.user_name}", user: user, channel: channel).to respond_with_slack_message(
        "#{user.slack_mention} and #{teammate.slack_mention} challenged #{opponent.slack_mention} and #{opponent2.slack_mention} to a match!"
      )
    end.to change(Challenge, :count).by(1)
    challenge = Challenge.last
    expect(challenge.channel).to eq channel
    expect(challenge.created_by).to eq user
    expect(challenge.challengers).to eq [teammate, user]
    expect(challenge.challenged).to eq [opponent2, opponent]
  end

  it 'creates a singles challenge by user name case-insensitive' do
    expect do
      expect(message: "@gamebot challenge #{opponent.user_name.capitalize}", user: user, channel: channel).to respond_with_slack_message(
        "#{user.slack_mention} challenged #{opponent.slack_mention} to a match!"
      )
    end.to change(Challenge, :count).by(1)
  end

  it 'requires an opponent' do
    expect do
      expect(message: '@gamebot challenge', user: user, channel: channel).to respond_with_slack_message(
        'Number of teammates (1) and opponents (0) must match.'
      )
    end.not_to change(Challenge, :count)
  end

  it 'requires the same number of opponents' do
    opponent1 = Fabricate(:user, channel: channel)
    opponent2 = Fabricate(:user, channel: channel)
    expect do
      expect(message: "@gamebot challenge #{opponent1.slack_mention} #{opponent2.slack_mention}", user: user, channel: channel).to respond_with_slack_message(
        'Number of teammates (1) and opponents (2) must match.'
      )
    end.not_to change(Challenge, :count)
  end

  context 'with unbalanced option enabled' do
    before do
      channel.update_attributes!(unbalanced: true)
    end

    it 'allows different number of opponents' do
      opponent1 = Fabricate(:user, channel: channel)
      opponent2 = Fabricate(:user, channel: channel)
      expect do
        expect(message: "@gamebot challenge #{opponent1.slack_mention} #{opponent2.slack_mention}", user: user, channel: channel).to respond_with_slack_message(
          "#{user.slack_mention} challenged #{opponent1.slack_mention} and #{opponent2.slack_mention} to a match!"
        )
      end.to change(Challenge, :count).by(1)
      challenge = Challenge.last
      expect(challenge.challengers).to eq [user]
      expect(challenge.challenged).to eq [opponent1, opponent2]
    end
  end

  it 'does not butcher names with special characters' do
    allow(channel.team.slack_client).to receive(:users_info)
    expect(message: '@gamebot challenge Jung-hwa', user: user, channel: channel).to respond_with_slack_message(
      "I don't know who Jung-hwa is!"
    )
  end

  context 'requires the opponent to be registered' do
    before do
      opponent.unregister!
    end

    it 'by slack id' do
      expect(message: "@gamebot challenge #{opponent.slack_mention}", user: user, channel: channel).to respond_with_slack_message(
        "I know who #{opponent.slack_mention} is, but they are unregistered. Ask them to _register_."
      )
    end

    it 'requires the opponent to be registered by name' do
      expect(message: "@gamebot challenge #{opponent.user_name}", user: user, channel: channel).to respond_with_slack_message(
        "I know who #{opponent.user_name} is, but they are unregistered. Ask them to _register_."
      )
    end
  end

  User::EVERYONE.each do |username|
    it "challenges #{username}" do
      expect do
        expect(message: "@gamebot challenge <!#{username}>", user: user, channel: channel).to respond_with_slack_message(
          "#{user.slack_mention} challenged anyone to a match!"
        )
      end.to change(Challenge, :count).by(1)
      challenge = Challenge.last
      expect(challenge.channel).to eq channel
      expect(challenge.created_by).to eq user
      expect(challenge.challengers).to eq [user]
      expect(challenge.challenged).to eq team.users.everyone
    end
  end
end
