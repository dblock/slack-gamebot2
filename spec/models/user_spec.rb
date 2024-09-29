# frozen_string_literal: true

require 'spec_helper'

describe User do
  let(:team) { Fabricate(:team) }
  let(:channel) { Fabricate(:channel, team: team) }

  describe '#to_s' do
    let(:user) { Fabricate(:user, channel: Fabricate(:channel, elo: 2), elo: 48) }

    it 'respects team elo' do
      expect(user.to_s).to include 'elo: 50'
    end

    context 'unregistered user' do
      before do
        user.update_attributes!(registered: false)
      end

      it 'hides name' do
        expect(user.to_s).to eq '<unregistered>: 0 wins, 0 losses (elo: 50)'
      end
    end

    context 'user with nickname' do
      before do
        user.update_attributes!(nickname: 'bob')
      end

      it 'rewrites user name' do
        expect(user.to_s).to eq 'bob: 0 wins, 0 losses (elo: 50)'
      end
    end

    context 'with a longest winning streak >= 3' do
      before do
        user.update_attributes!(winning_streak: 3)
      end

      it 'displays lws' do
        expect(user.to_s).to eq "#{user.user_name}: 0 wins, 0 losses (elo: 50, lws: 3)"
      end
    end

    context 'equal streaks' do
      before do
        user.update_attributes!(winning_streak: 5, losing_streak: 5)
      end

      it 'prefers winning streak' do
        expect(user.to_s).to eq "#{user.user_name}: 0 wins, 0 losses (elo: 50, lws: 5)"
      end
    end

    context 'with a longest losing streak >= 3' do
      before do
        user.update_attributes!(losing_streak: 3, winning_streak: 2)
      end

      it 'displays lls' do
        expect(user.to_s).to eq "#{user.user_name}: 0 wins, 0 losses (elo: 50, lls: 3)"
      end
    end
  end

  describe '#reset_all' do
    it 'resets all user stats' do
      user1 = Fabricate(:user, channel: channel, elo: 48, losses: 1, wins: 2, ties: 3, tau: 0.5)
      user2 = Fabricate(:user, channel: channel, elo: 54, losses: 2, wins: 1, tau: 1.5)
      described_class.reset_all!(user1.channel)
      user1.reload
      user2.reload
      expect(user1.wins).to eq 0
      expect(user1.losses).to eq 0
      expect(user1.ties).to eq 0
      expect(user1.tau).to eq 0
      expect(user1.elo).to eq 0
      expect(user1.rank).to be_nil
      expect(user1.winning_streak).to eq 0
      expect(user1.losing_streak).to eq 0
      expect(user1.elo_history).to eq []
      expect(user2.wins).to eq 0
      expect(user2.losses).to eq 0
      expect(user2.ties).to eq 0
      expect(user2.tau).to eq 0
      expect(user2.elo).to eq 0
      expect(user2.rank).to be_nil
      expect(user2.winning_streak).to eq 0
      expect(user2.losing_streak).to eq 0
      expect(user2.elo_history).to eq []
    end
  end

  describe '#rank!' do
    it 'updates when elo changes' do
      user = Fabricate(:user, channel: channel)
      expect(user.rank).to be_nil
      user.update_attributes!(elo: 65, wins: 1)
      expect(user.rank).to eq 1
    end

    it 'stores elo history' do
      user = Fabricate(:user, channel: channel)
      user.update_attributes!(elo: 65, wins: 1)
      expect(user.elo_history).to eq [0, 65]
      user.update_attributes!(elo: 45, wins: 2)
      expect(user.elo_history).to eq [0, 65, 45]
    end

    it 'ranks four players' do
      user1 = Fabricate(:user, channel: channel, elo: 100, wins: 4, losses: 0)
      user2 = Fabricate(:user, channel: channel, elo: 40, wins: 1, losses: 1)
      user3 = Fabricate(:user, channel: channel, elo: 60, wins: 2, losses: 0)
      user4 = Fabricate(:user, channel: channel, elo: 80, wins: 3, losses: 0)
      expect(user1.reload.rank).to eq 1
      expect(user2.reload.rank).to eq 4
      expect(user3.reload.rank).to eq 3
      expect(user4.reload.rank).to eq 2
    end

    it 'ranks players with the same elo and different wins' do
      user1 = Fabricate(:user, channel: channel, elo: 40, wins: 1, losses: 0)
      user2 = Fabricate(:user, channel: channel, elo: 40, wins: 4, losses: 0)
      expect(user1.reload.rank).to eq 2
      expect(user2.reload.rank).to eq 1
    end

    it 'ranks players with the same elo, wins and losses and different ties' do
      user1 = Fabricate(:user, channel: channel, elo: 40, wins: 1, losses: 0, ties: 0)
      user2 = Fabricate(:user, channel: channel, elo: 40, wins: 1, losses: 0, ties: 1)
      expect(user1.reload.rank).to eq 2
      expect(user2.reload.rank).to eq 1
    end

    it 'ranks players with the same elo and wins/losses equally' do
      user1 = Fabricate(:user, channel: channel, elo: 1, wins: 1, losses: 1)
      user2 = Fabricate(:user, channel: channel, elo: 2, wins: 1, losses: 1)
      expect(user1.rank).to eq 1
      expect(user1.rank).to eq user2.rank
    end

    it 'is updated for all users' do
      user1 = Fabricate(:user, channel: channel, elo: 65, wins: 1)
      expect(user1.rank).to eq 1
      user2 = Fabricate(:user, channel: channel, elo: 75, wins: 2)
      expect(user1.reload.rank).to eq 2
      expect(user2.rank).to eq 1
      user1.update_attributes!(elo: 100, wins: 3)
      expect(user1.rank).to eq 1
      expect(user2.reload.rank).to eq 2
    end

    it 'does not rank unregistered users' do
      user1 = Fabricate(:user, channel: channel, elo: 40, wins: 1, losses: 0, registered: false)
      user2 = Fabricate(:user, channel: channel, elo: 40, wins: 4, losses: 0)
      expect(user1.reload.rank).to be_nil
      expect(user2.reload.rank).to eq 1
    end
  end

  describe '.ranked' do
    it 'returns an empty list' do
      expect(described_class.ranked).to eq []
    end

    it 'ignores players without rank' do
      user1 = Fabricate(:user, channel: channel, elo: 1, wins: 1, losses: 1)
      Fabricate(:user, channel: channel)
      expect(described_class.ranked).to eq [user1]
    end
  end

  describe '.rank_section' do
    it 'returns a section' do
      user1 = Fabricate(:user, channel: channel, elo: 100, wins: 4, losses: 0)
      user2 = Fabricate(:user, channel: channel, elo: 40, wins: 1, losses: 1)
      user3 = Fabricate(:user, channel: channel, elo: 60, wins: 2, losses: 0)
      user4 = Fabricate(:user, channel: channel, elo: 80, wins: 3, losses: 0)
      [user1, user2, user3, user4].each(&:reload)
      expect(described_class.rank_section(channel, [user1])).to eq [user1]
      expect(described_class.rank_section(channel, [user1, user3])).to eq [user1, user4, user3]
      expect(described_class.rank_section(channel, [user1, user3, user4])).to eq [user1, user4, user3]
    end

    it 'limits by channel' do
      user = Fabricate(:user, channel: channel, elo: 100, wins: 4, losses: 0)
      expect(described_class.rank_section(Fabricate(:channel), [user])).to eq []
    end

    it 'only returns one unranked user' do
      user1 = Fabricate(:user, channel: channel)
      user2 = Fabricate(:user, channel: channel)
      expect(described_class.rank_section(channel, [user1])).to eq [user1]
      expect(described_class.rank_section(channel, [user1, user2])).to eq [user1, user2]
    end
  end

  describe '#calculate_streaks!' do
    let(:user) { Fabricate(:user, channel: channel) }

    it 'is 0 by default' do
      expect(user.winning_streak).to eq 0
      expect(user.losing_streak).to eq 0
    end

    it 'is 0 without matches' do
      user.calculate_streaks!
      expect(user.winning_streak).to eq 0
      expect(user.losing_streak).to eq 0
    end
  end
end
