# frozen_string_literal: true

require 'spec_helper'

describe Channel do
  context 'a public channel' do
    let!(:channel) { Fabricate(:channel) }

    context 'channel_admins' do
      it 'has no inviter' do
        expect(channel.channel_admins).to eq([])
      end

      context 'with an inviter' do
        let!(:user) { Fabricate(:user, channel: channel) }

        before do
          channel.update_attributes!(inviter_id: user.user_id)
        end

        it 'has an admin' do
          expect(channel.channel_admins).to eq([user])
          expect(channel.channel_admins_slack_mentions).to eq(user.slack_mention)
        end

        context 'with another admin' do
          let!(:another) { Fabricate(:user, channel: channel, is_admin: true) }

          it 'has two admins' do
            expect(channel.channel_admins.to_a.sort).to eq([user, another].sort)
            expect(channel.channel_admins_slack_mentions).to eq([user.slack_mention, another.slack_mention].or)
          end
        end

        context 'with an admin in another channel' do
          let!(:another) { Fabricate(:user, channel: Fabricate(:channel), is_admin: true) }

          it 'has one admin' do
            expect(channel.channel_admins).to eq([user])
            expect(channel.channel_admins_slack_mentions).to eq(user.slack_mention)
          end
        end

        context 'with a team admin' do
          let!(:another) { Fabricate(:user, channel: channel, is_admin: false) }

          before do
            channel.team.update_attributes!(activated_user_id: another.user_id)
          end

          it 'has two admins' do
            expect(channel.channel_admins.to_a.sort).to eq([user, another].sort)
            expect(channel.channel_admins_slack_mentions).to eq([user.slack_mention, another.slack_mention].or)
          end
        end

        context 'with a different team admin' do
          let!(:team_admin) { Fabricate(:user, channel: channel, is_admin: false) }
          let!(:another) { Fabricate(:user, channel: channel, is_admin: true) }

          before do
            channel.team.update_attributes!(activated_user_id: team_admin.user_id)
          end

          it 'has three admins' do
            expect(channel.channel_admins.to_a.sort).to eq([user, team_admin, another].sort)
          end
        end

        context 'with another owner' do
          let!(:another) { Fabricate(:user, channel: channel, is_owner: true) }

          it 'has two admins' do
            expect(channel.channel_admins.to_a.sort).to eq([user, another].sort)
            expect(channel.channel_admins_slack_mentions).to eq([user.slack_mention, another.slack_mention].or)
          end
        end
      end
    end

    describe '#find_or_create_by_mention!' do
      let(:user) { Fabricate(:user, channel: channel) }

      it 'finds by slack id' do
        expect(channel.find_or_create_by_mention!("<@#{user.user_id}>")).to eq user
      end

      it 'finds by username' do
        expect(channel.find_or_create_by_mention!(user.user_name)).to eq user
      end

      it 'finds by username is case-insensitive' do
        expect(channel.find_or_create_by_mention!(user.user_name.capitalize)).to eq user
      end

      it 'finds by username with special regex characters' do
        special_name = 'nog$()[]{}.*?^|'
        user.update_attributes!(user_name: special_name)
        expect(channel.find_or_create_by_mention!(special_name)).to eq user
      end

      it 'creates a new user when ID is known', vcr: { cassette_name: 'users_info' } do
        expect do
          channel.find_or_create_by_mention!('<@nobody>')
        end.to change(User, :count).by(1)
      end

      it 'requires a known user' do
        expect do
          channel.find_or_create_by_mention!('nobody')
        end.to raise_error SlackGamebot::Error, "I don't know who nobody is!"
      end

      context 'with an unregistered user' do
        let!(:user) { Fabricate(:user, channel: channel, registered: false) }

        it 'knows the unregistered user' do
          expect do
            channel.find_or_create_by_mention!(user.user_name)
          end.to raise_error SlackGamebot::Error, "I know who #{user.user_name} is, but they are unregistered. Ask them to _register_."
        end
      end
    end

    describe '#find_or_create_many_by_mention!' do
      let!(:users) { [Fabricate(:user, channel: channel), Fabricate(:user, channel: channel)] }

      it 'finds by slack_id or slack_mention' do
        results = channel.find_or_create_many_by_mention!([users.first.user_name, users.last.slack_mention])
        expect(results).to match_array(users)
      end

      it 'requires known users' do
        expect do
          channel.find_or_create_many_by_mention!(%w[foo bar])
        end.to raise_error SlackGamebot::Error, "I don't know who foo is!"
      end
    end

    describe '#find_or_create_by_slack_id!', vcr: { cassette_name: 'users_info' } do
      context 'without a user' do
        it 'creates a user' do
          expect do
            user = channel.find_or_create_by_slack_id!('U42')
            expect(user).not_to be_nil
            expect(user.user_id).to eq 'U42'
            expect(user.user_name).to eq 'username'
          end.to change(User, :count).by(1)
        end
      end

      context 'with a user' do
        let!(:user) { Fabricate(:user, channel: channel) }

        it 'creates another user' do
          expect do
            channel.find_or_create_by_slack_id!('U42')
          end.to change(User, :count).by(1)
        end

        it 'updates the username of the existing user' do
          expect do
            channel.find_or_create_by_slack_id!(user.user_id)
          end.not_to change(User, :count)
          expect(user.reload.user_name).to eq 'username'
        end
      end
    end

    describe '#api_url' do
      it 'sets the API url' do
        expect(channel.api_url).to eq "https://gamebot2.playplay.io/api/channels/#{channel._id}"
      end
    end

    describe '#aliases' do
      it 'defaults to empty' do
        expect(channel.aliases).to eq []
      end
    end

    describe '#aliases_s' do
      it 'defaults to empty' do
        expect(channel.aliases_s).to eq 'not set'
      end

      context 'with one alias' do
        before do
          channel.update_attributes!(aliases: ['one'])
        end

        it 'one' do
          expect(channel.aliases_s).to eq '`one`'
        end
      end

      context 'with two aliases' do
        before do
          channel.update_attributes!(aliases: %w[one two])
        end

        it 'one' do
          expect(channel.aliases_s).to eq '`one` and `two`'
        end
      end
    end

    describe 'slack_mention?' do
      it 'extracts slack id' do
        expect(described_class.slack_mention?('<#C07A7FS5AJY|pong>')).to eq 'C07A7FS5AJY'
        expect(described_class.slack_mention?('<#C07A7FS5AJY>')).to eq 'C07A7FS5AJY'
      end
    end
  end

  describe 'a private group channel' do
    let!(:channel) { Fabricate(:channel, is_group: true) }

    describe '#aliases_s' do
      it 'is not supported' do
        expect { channel.aliases_s }.to raise_error 'Bot aliases are not supported in private channels.'
      end
    end
  end

  describe 'leaderboard_s' do
    let!(:channel) { Fabricate(:channel) }

    let!(:user1) { Fabricate(:user, channel: channel, elo: 42, wins: 3, losses: 2) }
    let!(:user2) { Fabricate(:user, channel: channel, elo: 48, wins: 2, losses: 3) }
    let!(:user3) { Fabricate(:user, channel: channel, elo: 45, wins: 1, losses: 1) }

    before do
      User.rank!(channel)
    end

    it 'returns nil when there are no ranked players' do
      User.reset_all!(channel)
      expect(channel.leaderboard_s).to be_nil
    end

    it 'returns all ranked players sorted by rank' do
      expected = [
        "1. #{user2}",
        "2. #{user3}",
        "3. #{user1}"
      ].join("\n")
      expect(channel.leaderboard_s).to eq(expected)
    end

    it 'respects leaderboard_max when set' do
      channel.update_attributes!(leaderboard_max: 2)
      expected = [
        "1. #{user2}",
        "2. #{user3}"
      ].join("\n")
      expect(channel.leaderboard_s).to eq(expected)
    end

    it 'respects explicit max parameter' do
      expected = [
        "1. #{user2}",
        "2. #{user3}"
      ].join("\n")
      expect(channel.leaderboard_s(max: 2)).to eq(expected)
    end

    it 'respects explicit reverse parameter' do
      expected = [
        "1. #{user1}",
        "2. #{user3}"
      ].join("\n")
      expect(channel.leaderboard_s(max: 2, reverse: true)).to eq(expected)
    end

    it 'ignores unregistered users' do
      user2.unregister!
      User.rank!(channel)
      expected = [
        "1. #{user3}",
        "2. #{user1}"
      ].join("\n")
      expect(channel.leaderboard_s).to eq(expected)
    end

    it 'returns all players when max is nil' do
      channel.update_attributes!(leaderboard_max: nil)
      expected = [
        "1. #{user2}",
        "2. #{user3}",
        "3. #{user1}"
      ].join("\n")
      expect(channel.leaderboard_s).to eq(expected)
    end

    it 'returns all players when max is 0' do
      channel.update_attributes!(leaderboard_max: 0)
      expected = [
        "1. #{user2}",
        "2. #{user3}",
        "3. #{user1}"
      ].join("\n")
      expect(channel.leaderboard_s).to eq(expected)
    end

    it 'returns all players when max is negative' do
      channel.update_attributes!(leaderboard_max: -1)
      expected = [
        "1. #{user2}",
        "2. #{user3}",
        "3. #{user1}"
      ].join("\n")
      expect(channel.leaderboard_s).to eq(expected)
    end
  end
end
