# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Commands::Challenge do
  include_context 'channel'

  let(:user) { Fabricate(:user, channel: channel, user_name: 'username') }
  let(:opponent) { Fabricate(:user, channel: channel) }

  it 'creates a singles challenge by user id' do
    expect do
      expect(message: "<@bot_user_id> challenge <@#{opponent.user_id}>", user: user, channel: channel).to respond_with_slack_message(
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
      expect(message: "<@bot_user_id> challenge #{opponent.slack_mention}", user: user, channel: channel).to respond_with_slack_message(
        "#{user.slack_mention} challenged #{opponent.slack_mention} to a match!"
      )
    end.to change(Challenge, :count).by(1)
  end

  it 'creates a doubles challenge by user name' do
    opponent2 = Fabricate(:user, channel: channel)
    teammate = Fabricate(:user, channel: channel)
    expect do
      expect(message: "<@bot_user_id> challenge #{opponent.slack_mention} #{opponent2.user_name} with #{teammate.user_name}", user: user, channel: channel).to respond_with_slack_message(
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
      expect(message: "<@bot_user_id> challenge #{opponent.user_name.capitalize}", user: user, channel: channel).to respond_with_slack_message(
        "#{user.slack_mention} challenged #{opponent.slack_mention} to a match!"
      )
    end.to change(Challenge, :count).by(1)
  end

  it 'requires an opponent' do
    expect do
      expect(message: '<@bot_user_id> challenge', user: user, channel: channel).to respond_with_slack_message(
        'Number of teammates (1) and opponents (0) must match.'
      )
    end.not_to change(Challenge, :count)
  end

  it 'requires the same number of opponents' do
    opponent1 = Fabricate(:user, channel: channel)
    opponent2 = Fabricate(:user, channel: channel)
    expect do
      expect(message: "<@bot_user_id> challenge #{opponent1.slack_mention} #{opponent2.slack_mention}", user: user, channel: channel).to respond_with_slack_message(
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
        expect(message: "<@bot_user_id> challenge #{opponent1.slack_mention} #{opponent2.slack_mention}", user: user, channel: channel).to respond_with_slack_message(
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
    expect(message: '<@bot_user_id> challenge Jung-hwa', user: user, channel: channel).to respond_with_slack_message(
      "I don't know who Jung-hwa is!"
    )
  end

  context 'requires the challenger to be registered' do
    before do
      user.unregister!
    end

    it 'cannot challenge when unregistered' do
      expect(message: "<@bot_user_id> challenge #{opponent.slack_mention}", user: user.user_id, channel: channel).to respond_with_slack_message(
        "You're not registered. Type _register_ to register."
      )
    end
  end

  context 'requires the opponent to be registered' do
    before do
      opponent.unregister!
    end

    it 'by slack id' do
      expect(message: "<@bot_user_id> challenge #{opponent.slack_mention}", user: user, channel: channel).to respond_with_slack_message(
        "I know who #{opponent.slack_mention} is, but they are unregistered. Ask them to _register_."
      )
    end

    it 'requires the opponent to be registered by name' do
      expect(message: "<@bot_user_id> challenge #{opponent.user_name}", user: user, channel: channel).to respond_with_slack_message(
        "I know who #{opponent.user_name} is, but they are unregistered. Ask them to _register_."
      )
    end
  end

  User::EVERYONE.each do |username|
    it "challenges #{username}" do
      expect do
        expect(message: "<@bot_user_id> challenge <!#{username}>", user: user, channel: channel).to respond_with_slack_message(
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

  context 'DM' do
    include_context 'dm'

    let(:admin) { Fabricate(:admin, team: team) }

    it 'challenge' do
      expect(message: 'challenge @someone', channel: 'DM', user: admin.user_id).to respond_with_slack_message([
        'Invite me to a channel to start a new leaderboard.',
        'Type `<@bot_user_id> help` for more options.'
      ].join("\n"))
    end
  end

  context 'with max challenges per day set' do
    let(:other_challenger) { Fabricate(:user, channel: channel) }
    let(:other_challenged) { Fabricate(:user, channel: channel) }

    before do
      channel.update_attributes!(max_challenges_per_day: 1)
      Fabricate(:challenge, team: team, challengers: [other_challenger], challenged: [other_challenged])
    end

    it 'cannot challenge when the daily channel limit is reached' do
      expect do
        expect(message: "<@bot_user_id> challenge #{opponent.slack_mention}", user: user, channel: channel).to respond_with_slack_message(
          'Only 1 challenge allowed per day in this channel, 1 already issued today.'
        )
      end.not_to change(Challenge, :count)
    end

    context 'with a limit of 2' do
      before { channel.update_attributes!(max_challenges_per_day: 2) }

      it 'can challenge when under the daily limit' do
        expect do
          expect(message: "<@bot_user_id> challenge #{opponent.slack_mention}", user: user, channel: channel).to respond_with_slack_message(
            "#{user.slack_mention} challenged #{opponent.slack_mention} to a match!"
          )
        end.to change(Challenge, :count).by(1)
      end
    end
  end

  context 'with max challenges per user set' do
    let(:other_opponent) { Fabricate(:user, channel: channel) }

    before do
      channel.update_attributes!(max_challenges_per_user: 1)
      Fabricate(:played_challenge, team: team, challengers: [user], challenged: [opponent])
    end

    it 'cannot challenge a second time on the same day' do
      expect do
        expect(message: "<@bot_user_id> challenge #{other_opponent.slack_mention}", user: user, channel: channel).to respond_with_slack_message(
          'Only 1 challenge allowed per day per user, 1 already created today.'
        )
      end.not_to change(Challenge, :count)
    end

    it 'allows a different user to challenge when another user is at their limit' do
      different_user = Fabricate(:user, channel: channel)
      expect do
        expect(message: "<@bot_user_id> challenge #{other_opponent.slack_mention}", user: different_user, channel: channel).to respond_with_slack_message(
          "#{different_user.slack_mention} challenged #{other_opponent.slack_mention} to a match!"
        )
      end.to change(Challenge, :count).by(1)
    end

    context 'with a limit of 2' do
      before { channel.update_attributes!(max_challenges_per_user: 2) }

      it 'can issue a second challenge when under the per-user limit' do
        expect do
          expect(message: "<@bot_user_id> challenge #{other_opponent.slack_mention}", user: user, channel: channel).to respond_with_slack_message(
            "#{user.slack_mention} challenged #{other_opponent.slack_mention} to a match!"
          )
        end.to change(Challenge, :count).by(1)
      end
    end
  end

  context 'with max games per user set' do
    let(:other_opponent) { Fabricate(:user, channel: channel) }

    before do
      channel.update_attributes!(max_games_per_user: 1)
      # Use a played challenge so the user isn't in an open challenge (avoids unique-challenge error)
      Fabricate(:played_challenge, channel: channel, challengers: [user], challenged: [opponent])
    end

    it 'cannot create a challenge when the challenger is at their daily game limit' do
      expect do
        expect(message: "<@bot_user_id> challenge #{other_opponent.slack_mention}", user: user, channel: channel).to respond_with_slack_message(
          "Only 1 game allowed per day per user, #{user.display_name} already has 1 today."
        )
      end.not_to change(Challenge, :count)
    end

    it 'allows a different user to challenge when another is at their game limit' do
      different_user = Fabricate(:user, channel: channel)
      expect do
        expect(message: "<@bot_user_id> challenge #{other_opponent.slack_mention}", user: different_user, channel: channel).to respond_with_slack_message(
          "#{different_user.slack_mention} challenged #{other_opponent.slack_mention} to a match!"
        )
      end.to change(Challenge, :count).by(1)
    end
  end
end
