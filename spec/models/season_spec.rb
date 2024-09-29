# frozen_string_literal: true

require 'spec_helper'

describe Season do
  include_context 'channel'

  context 'with challenges' do
    let!(:open_challenge) { Fabricate(:challenge, channel: channel) }
    let!(:matches) { Array.new(3) { Fabricate(:match, channel: channel) } }
    let!(:season) { Fabricate(:season, team: channel.team, channel: channel) }

    it 'archives challenges' do
      expect(season.challenges.count).to eq 4
    end

    it 'cancels open challenges' do
      expect(open_challenge.reload.state).to eq ChallengeState::CANCELED
    end

    it 'resets users' do
      expect(User.all.detect { |u| u.wins != 0 || u.losses != 0 }).to be_nil
    end

    it 'saves user ranks' do
      expect(season.user_ranks.count).to eq 6
    end

    it 'to_s' do
      expect(season.to_s).to eq "#{season.created_at.strftime('%F')}: #{season.winners.map(&:to_s).and}, 3 matches, 6 players"
    end
  end

  context 'without challenges' do
    let(:season) { Season.new(team: channel.team, channel: channel) }

    it 'cannot be created' do
      expect(season).not_to be_valid
      expect(season.errors.messages).to eq(challenges: ['No matches have been recorded.'])
    end

    it 'to_s' do
      expect(season.to_s).to eq 'Current: n/a, 0 matches, 0 players'
    end
  end

  context 'without challenges and a lost match' do
    let(:challenger) { Fabricate(:user, channel: channel) }
    let(:challenged) { Fabricate(:user, channel: channel) }
    let(:season) { Season.new(team: channel.team, channel: channel) }

    before do
      Match.lose!(team: channel.team, channel: channel, winners: [challenger], losers: [challenged])
    end

    it 'can be created' do
      expect(season).to be_valid
    end

    it 'to_s' do
      expect(season.to_s).to eq "Current: #{season.winners.map(&:to_s).and}, 1 match, 2 players"
    end

    it 'has one winner' do
      expect(season.winners.count).to eq 1
    end
  end

  context 'current season with one match' do
    let!(:match) { Fabricate(:match, channel: channel) }
    let(:season) { Season.new(team: channel.team, channel: channel) }

    it 'to_s' do
      expect(season.to_s).to eq "Current: #{season.winners.map(&:to_s).and}, 1 match, 2 players"
    end

    it 'has one winner' do
      expect(season.winners.count).to eq 1
    end
  end

  context 'current season with multiple matches and one winner' do
    let(:user) { Fabricate(:user, channel: channel) }
    let!(:matches) { Array.new(3) { Fabricate(:match, channel: channel, challenge: Fabricate(:challenge, channel: channel, challengers: [user])) } }
    let(:season) { Season.new(team: channel.team, channel: channel) }

    it 'to_s' do
      expect(season.to_s).to eq "Current: #{season.winners.map(&:to_s).and}, 3 matches, 4 players"
    end

    it 'has one winner' do
      expect(season.winners.count).to eq 1
      expect(season.winners.first.wins).to eq 3
    end

    context 'with an unplayed challenge' do
      before do
        Fabricate(:challenge, channel: channel)
      end

      it 'only counts played matches' do
        expect(season.to_s).to eq "Current: #{season.winners.map(&:to_s).and}, 3 matches, 4 players"
      end
    end
  end

  context 'current season with two winners' do
    let!(:matches) { Array.new(2) { Fabricate(:match, channel: channel) } }
    let!(:matches) { Array.new(2) { Fabricate(:match, channel: channel) } }
    let(:season) { Season.new(team: channel.team, channel: channel) }

    it 'has two winners' do
      expect(season.winners.count).to eq 2
      expect(season.winners.map(&:wins).uniq).to eq([1])
    end
  end
end
