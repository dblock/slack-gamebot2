# frozen_string_literal: true

require 'spec_helper'

describe Challenge do
  describe '#to_s' do
    let(:challenge) { Fabricate(:challenge) }

    it 'displays challenge' do
      expect(challenge.to_s).to eq "a challenge between #{challenge.challengers.first.user_name} and #{challenge.challenged.first.user_name}"
    end

    context 'unregistered users' do
      before do
        challenge.challengers.first.unregister!
      end

      it 'removes user name' do
        expect(challenge.to_s).to eq "a challenge between <unregistered> and #{challenge.challenged.first.user_name}"
      end
    end

    context 'users with nickname' do
      before do
        challenge.challengers.first.update_attributes!(nickname: 'bob')
      end

      it 'rewrites user name' do
        expect(challenge.to_s).to eq "a challenge between bob and #{challenge.challenged.first.user_name}"
      end
    end
  end

  context 'find_by_user' do
    let(:challenge) { Fabricate(:challenge) }

    it 'finds a challenge by challenger' do
      challenge.challengers.each do |challenger|
        expect(described_class.find_by_user(challenger)).to eq challenge
      end
    end

    it 'finds a challenge by challenged' do
      challenge.challenged.each do |challenger|
        expect(described_class.find_by_user(challenger)).to eq challenge
      end
    end
  end

  pending 'find_open_challenge'

  describe '#split_teammates_and_opponents' do
    let!(:channel) { Fabricate(:channel) }
    let!(:challenger) { Fabricate(:user, channel: channel) }

    it 'splits a single challenge' do
      opponent = Fabricate(:user, user_name: 'username')
      challengers, opponents = described_class.split_teammates_and_opponents(challenger, ['username'])
      expect(challengers).to eq([challenger])
      expect(opponents).to eq([opponent])
    end

    it 'splits a double challenge' do
      teammate = Fabricate(:user, channel: channel)
      opponent1 = Fabricate(:user, channel: channel, user_name: 'username')
      opponent2 = Fabricate(:user, channel: channel)
      challengers, opponents = described_class.split_teammates_and_opponents(challenger, ['username', opponent2.slack_mention, 'with', teammate.slack_mention])
      expect(challengers).to eq([challenger, teammate])
      expect(opponents).to eq([opponent1, opponent2])
    end

    it 'requires known opponents' do
      allow(channel.team.slack_client).to receive(:users_info)
      expect do
        described_class.split_teammates_and_opponents(challenger, ['username'])
      end.to raise_error SlackGamebot::Error, "I don't know who username is!"
    end
  end

  describe '#create_from_teammates_and_opponents!' do
    let(:team) { Fabricate(:team) }
    let!(:channel) { Fabricate(:channel, team: team) }
    let!(:challenger) { Fabricate(:user, channel: channel) }
    let(:teammate) { Fabricate(:user, channel: channel) }
    let(:opponent) { Fabricate(:user, channel: channel) }
    let(:client) { SlackGamebot::Web::Client.new(token: 'token', team: team) }

    it 'requires an opponent' do
      expect do
        described_class.create_from_teammates_and_opponents!(challenger, [])
      end.to raise_error Mongoid::Errors::Validations, /Number of teammates \(1\) and opponents \(0\) must match./
    end

    it 'requires the same number of opponents' do
      expect do
        described_class.create_from_teammates_and_opponents!(challenger, [opponent.slack_mention, 'with', teammate.slack_mention])
      end.to raise_error Mongoid::Errors::Validations, /Number of teammates \(2\) and opponents \(1\) must match./
    end

    context 'with unbalanced option enabled' do
      before do
        challenger.channel.update_attributes!(unbalanced: true)
      end

      it 'requires an opponent' do
        expect do
          described_class.create_from_teammates_and_opponents!(challenger, [])
        end.to raise_error Mongoid::Errors::Validations, /Number of teammates \(1\) and opponents \(0\) must match./
      end

      it 'does not require the same number of opponents' do
        expect do
          described_class.create_from_teammates_and_opponents!(challenger, [opponent.slack_mention, 'with', teammate.slack_mention])
        end.not_to raise_error
      end
    end

    it 'requires another opponent' do
      expect do
        described_class.create_from_teammates_and_opponents!(challenger, [challenger.slack_mention])
      end.to raise_error Mongoid::Errors::Validations, /#{challenger.user_name} cannot play against themselves./
    end

    it 'uniques opponents mentioned multiple times' do
      expect do
        described_class.create_from_teammates_and_opponents!(challenger, [opponent.slack_mention, opponent.slack_mention, 'with', teammate.slack_mention])
      end.to raise_error Mongoid::Errors::Validations, /Number of teammates \(2\) and opponents \(1\) must match./
    end

    context 'with another singles proposed challenge' do
      let(:challenge) { Fabricate(:challenge) }

      it 'cannot create a duplicate challenge for the challenger' do
        existing_challenger = challenge.challengers.first
        expect do
          described_class.create_from_teammates_and_opponents!(challenger, [existing_challenger.slack_mention])
        end.to raise_error Mongoid::Errors::Validations, /#{existing_challenger.user_name} can't play./
      end

      it 'cannot create a duplicate challenge for the challenge' do
        existing_challenger = challenge.challenged.first
        expect do
          described_class.create_from_teammates_and_opponents!(challenger, [existing_challenger.slack_mention])
        end.to raise_error Mongoid::Errors::Validations, /#{existing_challenger.user_name} can't play./
      end
    end

    context 'with another doubles proposed challenge' do
      let(:challenge) { Fabricate(:challenge, challengers: [Fabricate(:user, channel: channel), Fabricate(:user, channel: channel)], challenged: [Fabricate(:user, channel: channel), Fabricate(:user, channel: channel)]) }

      it 'cannot create a duplicate challenge for the challenger' do
        existing_challenger = challenge.challengers.last
        expect do
          described_class.create_from_teammates_and_opponents!(challenger, [existing_challenger.slack_mention])
        end.to raise_error Mongoid::Errors::Validations, /#{existing_challenger.user_name} can't play./
      end
    end

    context 'with max_challenges_per_day set' do
      before do
        channel.update_attributes!(max_challenges_per_day: 2)
      end

      it 'allows challenges up to the daily limit' do
        opp1 = Fabricate(:user, channel: channel)
        opp2 = Fabricate(:user, channel: channel)
        described_class.create_from_teammates_and_opponents!(challenger, [opp1.slack_mention])
        described_class.create_from_teammates_and_opponents!(Fabricate(:user, channel: channel), [opp2.slack_mention])
        expect(channel.challenges.count).to eq 2
      end

      it 'raises an error when the daily channel limit is reached' do
        opp1 = Fabricate(:user, channel: channel)
        opp2 = Fabricate(:user, channel: channel)
        opp3 = Fabricate(:user, channel: channel)
        described_class.create_from_teammates_and_opponents!(challenger, [opp1.slack_mention])
        described_class.create_from_teammates_and_opponents!(Fabricate(:user, channel: channel), [opp2.slack_mention])
        expect do
          described_class.create_from_teammates_and_opponents!(Fabricate(:user, channel: channel), [opp3.slack_mention])
        end.to raise_error Mongoid::Errors::Validations, /Only 2 challenges allowed per day in this channel, 2 already issued today./
      end
    end

    context 'with max_challenges_per_user set' do
      before do
        channel.update_attributes!(max_challenges_per_user: 1)
      end

      it 'allows the user to challenge up to the per-user daily limit' do
        opp1 = Fabricate(:user, channel: channel)
        described_class.create_from_teammates_and_opponents!(challenger, [opp1.slack_mention])
        expect(channel.challenges.count).to eq 1
      end

      it 'raises an error when the per-user daily limit is reached' do
        opp1 = Fabricate(:user, channel: channel)
        opp2 = Fabricate(:user, channel: channel)
        described_class.create_from_teammates_and_opponents!(challenger, [opp1.slack_mention])
        expect do
          described_class.create_from_teammates_and_opponents!(challenger, [opp2.slack_mention])
        end.to raise_error Mongoid::Errors::Validations, /Only 1 challenge allowed per day per user, 1 already created today./
      end

      it 'allows a different user to challenge when one user is at their limit' do
        opp1 = Fabricate(:user, channel: channel)
        opp2 = Fabricate(:user, channel: channel)
        another_challenger = Fabricate(:user, channel: channel)
        described_class.create_from_teammates_and_opponents!(challenger, [opp1.slack_mention])
        expect do
          described_class.create_from_teammates_and_opponents!(another_challenger, [opp2.slack_mention])
        end.not_to raise_error
      end
    end

    context 'with max_games_per_user set' do
      before do
        channel.update_attributes!(max_games_per_user: 1)
      end

      it 'blocks the challenger from creating a new challenge when at their game limit' do
        opp1 = Fabricate(:user, channel: channel)
        opp2 = Fabricate(:user, channel: channel)
        c = described_class.create_from_teammates_and_opponents!(challenger, [opp1.slack_mention])
        c.accept!(opp1)
        expect do
          described_class.create_from_teammates_and_opponents!(challenger, [opp2.slack_mention])
        end.to raise_error Mongoid::Errors::Validations, /Only 1 game allowed per day per user, #{challenger.display_name} already has 1 today./
      end

      it 'allows a challenger under their game limit to create a challenge' do
        opp1 = Fabricate(:user, channel: channel)
        expect do
          described_class.create_from_teammates_and_opponents!(challenger, [opp1.slack_mention])
        end.not_to raise_error
      end
    end
  end

  describe '#accept!' do
    context 'with max_games_per_user set' do
      let(:team) { Fabricate(:team) }
      let!(:channel) { Fabricate(:channel, team: team, max_games_per_user: 1) }

      it 'blocks acceptance when the acceptor is at their daily game limit' do
        player_a = Fabricate(:user, channel: channel)
        player_b = Fabricate(:user, channel: channel)
        player_c = Fabricate(:user, channel: channel)
        # player_b already has 1 game today via a completed challenge (PLAYED = not open, counts toward daily total)
        Fabricate(:played_challenge, channel: channel, challengers: [player_a], challenged: [player_b])
        # player_c challenges player_b; player_b has no PROPOSED/ACCEPTED challenge so creation is OK
        challenge = Fabricate(:challenge, channel: channel, challengers: [player_c], challenged: [player_b])
        expect do
          challenge.accept!(player_b)
        end.to raise_error SlackGamebot::Error, /Only 1 game allowed per day per user, #{player_b.display_name} already has 1 today./
      end

      it 'allows acceptance when both sides are under their daily game limit' do
        player_a = Fabricate(:user, channel: channel)
        player_b = Fabricate(:user, channel: channel)
        challenge = Fabricate(:challenge, channel: channel, challengers: [player_a], challenged: [player_b])
        expect { challenge.accept!(player_b) }.not_to raise_error
      end
    end
  end

  describe '#accept! (original)' do
    let(:challenge) { Fabricate(:challenge) }

    it 'can be accepted' do
      accepted_by = challenge.challenged.first
      challenge.accept!(accepted_by)
      expect(challenge.updated_by).to eq accepted_by
      expect(challenge.state).to eq ChallengeState::ACCEPTED
    end

    it 'requires accepted_by' do
      challenge.state = ChallengeState::ACCEPTED
      expect(challenge).not_to be_valid
    end

    it 'cannot be accepted by another player' do
      expect do
        challenge.accept!(challenge.challengers.first)
      end.to raise_error Mongoid::Errors::Validations, /Only #{challenge.challenged.map(&:user_name).or} can accept this challenge./
    end

    it 'cannot be accepted twice' do
      accepted_by = challenge.challenged.first
      challenge.accept!(accepted_by)
      expect do
        challenge.accept!(accepted_by)
      end.to raise_error SlackGamebot::Error, /Challenge has already been accepted./
    end
  end

  describe '#decline!' do
    let(:challenge) { Fabricate(:challenge) }

    it 'can be declined' do
      declined_by = challenge.challenged.first
      challenge.decline!(declined_by)
      expect(challenge.updated_by).to eq declined_by
      expect(challenge.state).to eq ChallengeState::DECLINED
    end

    it 'requires declined_by' do
      challenge.state = ChallengeState::DECLINED
      expect(challenge).not_to be_valid
    end

    it 'cannot be declined by another player' do
      expect do
        challenge.decline!(challenge.challengers.first)
      end.to raise_error Mongoid::Errors::Validations, /Only #{challenge.challenged.map(&:user_name).or} can decline this challenge./
    end

    it 'cannot be declined twice' do
      declined_by = challenge.challenged.first
      challenge.decline!(declined_by)
      expect do
        challenge.decline!(declined_by)
      end.to raise_error SlackGamebot::Error, /Challenge has already been declined./
    end
  end

  describe '#cancel!' do
    let(:team) { Fabricate(:team) }
    let(:channel) { Fabricate(:channel, team: team) }
    let(:challenge) { Fabricate(:challenge, channel: channel) }

    it 'can be canceled by challenger' do
      canceled_by = challenge.challengers.first
      challenge.cancel!(canceled_by)
      expect(challenge.updated_by).to eq canceled_by
      expect(challenge.state).to eq ChallengeState::CANCELED
    end

    it 'can be canceled by challenged' do
      canceled_by = challenge.challenged.first
      challenge.cancel!(canceled_by)
      expect(challenge.updated_by).to eq canceled_by
      expect(challenge.state).to eq ChallengeState::CANCELED
    end

    it 'requires canceled_by' do
      challenge.state = ChallengeState::CANCELED
      expect(challenge).not_to be_valid
    end

    it 'cannot be canceled_by by another player' do
      player = Fabricate(:user, channel: channel)
      expect do
        challenge.cancel!(player)
      end.to raise_error Mongoid::Errors::Validations, /Only #{challenge.challengers.map(&:display_name).and} or #{challenge.challenged.map(&:display_name).and} can cancel this challenge./
    end

    it 'cannot be canceled_by twice' do
      canceled_by = challenge.challengers.first
      challenge.cancel!(canceled_by)
      expect do
        challenge.cancel!(canceled_by)
      end.to raise_error SlackGamebot::Error, /Challenge has already been canceled./
    end
  end

  describe '#lose!' do
    let(:challenge) { Fabricate(:challenge) }

    before do
      challenge.accept!(challenge.challenged.first)
    end

    it 'can be lost by the challenger' do
      expect do
        challenge.lose!(challenge.challengers.first)
      end.to change(Match, :count).by(1)
      match = Match.last
      expect(match.challenge).to eq challenge
      expect(match.winners).to eq challenge.challenged
      expect(match.losers).to eq challenge.challengers
      expect(match.winners.all? { |player| player.wins == 1 && player.losses == 0 }).to be true
      expect(match.losers.all? { |player| player.wins == 0 && player.losses == 1 }).to be true
    end

    it 'can be lost by the challenged' do
      expect do
        challenge.lose!(challenge.challenged.first)
      end.to change(Match, :count).by(1)
      match = Match.last
      expect(match.challenge).to eq challenge
      expect(match.winners).to eq challenge.challengers
      expect(match.losers).to eq challenge.challenged
      expect(match.winners.all? { |player| player.wins == 1 && player.losses == 0 }).to be true
      expect(match.losers.all? { |player| player.wins == 0 && player.losses == 1 }).to be true
    end
  end

  describe '#draw!' do
    let(:challenge) { Fabricate(:challenge) }

    before do
      challenge.accept!(challenge.challenged.first)
    end

    it 'requires both sides to draw' do
      expect do
        challenge.draw!(challenge.challengers.first)
      end.not_to change(Match, :count)
      expect do
        challenge.draw!(challenge.challenged.first)
      end.to change(Match, :count).by(1)
      match = Match.last
      expect(match.tied?).to be true
      expect(match.challenge).to eq challenge
      expect(match.winners).to eq challenge.challengers
      expect(match.losers).to eq challenge.challenged
      expect(match.winners.all? { |player| player.wins == 0 && player.losses == 0 && player.ties == 1 }).to be true
      expect(match.losers.all? { |player| player.wins == 0 && player.losses == 0 && player.ties == 1 }).to be true
    end
  end

  context 'a new challenge' do
    let(:played_challenge) { Fabricate(:played_challenge) }
    let(:new_challenge) { Fabricate(:challenge, challengers: played_challenge.challengers, challenged: played_challenge.challenged) }

    it 'does not render the played challenge invalid' do
      expect(new_challenge).to be_valid
      expect(played_challenge).to be_valid
    end
  end

  describe '#expire!' do
    let(:challenge) { Fabricate(:challenge) }

    it 'expires a proposed challenge' do
      challenge.expire!
      expect(challenge.reload.state).to eq ChallengeState::EXPIRED
    end

    it 'cannot expire an already accepted challenge' do
      challenge.update_attributes!(state: ChallengeState::ACCEPTED, updated_by: challenge.challenged.first)
      expect { challenge.expire! }.to raise_error(SlackGamebot::Error, 'Challenge has already been accepted.')
    end
  end

  describe '#remind!' do
    let(:challenge) { Fabricate(:accepted_challenge) }

    it 'sets reminded_at on an accepted challenge' do
      expect(challenge.channel).to receive(:inform!)
      challenge.remind!
      expect(challenge.reload.reminded_at).not_to be_nil
    end

    it 'cannot remind a proposed challenge' do
      expect { Fabricate(:challenge).remind! }.to raise_error(SlackGamebot::Error, 'Challenge has already been proposed.')
    end
  end
end
