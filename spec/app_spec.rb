# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::App do
  subject do
    described_class.instance
  end

  describe '#instance' do
    it 'is an instance of the market app' do
      expect(subject).to be_a(SlackRubyBotServer::App)
      expect(subject).to be_an_instance_of(described_class)
    end
  end

  context 'teams' do
    let!(:active_team) { Fabricate(:team, created_at: Time.now.utc) }
    let!(:active_team_one_week_ago) { Fabricate(:team, created_at: 1.week.ago) }
    let!(:active_team_four_weeks_ago) { Fabricate(:team, created_at: 5.weeks.ago) }
    let!(:subscribed_team_a_month_ago) { Fabricate(:team, created_at: 1.month.ago, subscribed: true) }
    let(:teams) { [active_team, active_team_one_week_ago, active_team_four_weeks_ago, subscribed_team_a_month_ago] }

    before do
      allow(Team).to receive(:active).and_return(teams)
    end

    describe '#deactivate_dead_teams!' do
      it 'deactivates teams inactive for two weeks' do
        expect(active_team).not_to receive(:inform!)
        expect(active_team_one_week_ago).not_to receive(:inform!)
        expect(active_team_four_weeks_ago).to receive(:deactivate!).and_call_original
        expect(subscribed_team_a_month_ago).not_to receive(:inform!)
        subject.send(:deactivate_dead_teams!)
        expect(active_team.reload.active).to be true
        expect(active_team_one_week_ago.reload.active).to be true
        expect(active_team_four_weeks_ago.reload.active).to be false
        expect(subscribed_team_a_month_ago.reload.active).to be true
        expect_any_instance_of(Team).to receive(:inform!).with(SlackGamebot::App::DEAD_MESSAGE).once
        subject.send(:inform_dead_teams!)
      end
    end
  end

  context 'challenges' do
    let!(:channel) { Fabricate(:channel) }
    let!(:proposed_challenge) { Fabricate(:challenge, channel: channel, created_at: 500.minutes.ago) }
    let!(:recent_challenge) { Fabricate(:challenge, channel: channel, created_at: 400.minutes.ago) }

    describe '#expire_challenges!' do
      it 'expires proposed challenges older than the expiry' do
        expect_any_instance_of(Channel).to receive(:inform!).with("#{proposed_challenge} has expired.")
        subject.send(:expire_challenges!)
        expect(proposed_challenge.reload.state).to eq ChallengeState::EXPIRED
        expect(recent_challenge.reload.state).to eq ChallengeState::PROPOSED
      end

      it 'does not expire challenges when expiry is never' do
        channel.update_attributes!(expire: nil)
        expect_any_instance_of(Channel).not_to receive(:inform!)
        subject.send(:expire_challenges!)
        expect(proposed_challenge.reload.state).to eq ChallengeState::PROPOSED
      end
    end

    describe '#remind_challenges!' do
      let!(:accepted_challenge) do
        Fabricate(:accepted_challenge, channel: channel, updated_at: 1500.minutes.ago)
      end
      let!(:recent_accepted_challenge) do
        Fabricate(:accepted_challenge, channel: channel, updated_at: 60.minutes.ago)
      end

      it 'reminds accepted challenges older than the reminder threshold' do
        players = (accepted_challenge.challengers + accepted_challenge.challenged).map(&:slack_mention).and
        expect_any_instance_of(Channel).to receive(:inform!).with(
          "Hey #{players}, #{accepted_challenge} was accepted but never recorded. Please record the match result."
        )
        subject.send(:remind_challenges!)
        expect(accepted_challenge.reload.reminded_at).not_to be_nil
        expect(recent_accepted_challenge.reload.reminded_at).to be_nil
      end

      it 'does not remind the same challenge again within 24 hours' do
        accepted_challenge.update_attributes!(reminded_at: Time.now.utc)
        expect_any_instance_of(Channel).not_to receive(:inform!)
        subject.send(:remind_challenges!)
      end

      it 'reminds again after 24 hours' do
        accepted_challenge.set(reminded_at: 25.hours.ago)
        players = (accepted_challenge.challengers + accepted_challenge.challenged).map(&:slack_mention).and
        expect_any_instance_of(Channel).to receive(:inform!).with(
          "Hey #{players}, #{accepted_challenge} was accepted but never recorded. Please record the match result."
        )
        subject.send(:remind_challenges!)
      end

      it 'does not remind when remind is never' do
        channel.update_attributes!(remind: nil)
        expect_any_instance_of(Channel).not_to receive(:inform!)
        subject.send(:remind_challenges!)
        expect(accepted_challenge.reload.reminded_at).to be_nil
      end
    end
  end

  context 'subscribed' do
    include_context 'stripe mock'
    let(:plan) { stripe_helper.create_plan(id: 'slack-gamebot2-yearly', amount: 4999, name: 'Plan') }
    let(:customer) { Stripe::Customer.create(source: stripe_helper.generate_card_token, plan: plan.id, email: 'foo@bar.com') }
    let!(:team) { Fabricate(:team, subscribed: true, stripe_customer_id: customer.id) }

    describe '#check_subscribed_teams!' do
      it 'ignores active subscriptions' do
        expect_any_instance_of(Team).not_to receive(:inform!)
        subject.send(:check_subscribed_teams!)
      end

      it 'notifies past due subscription' do
        customer.subscriptions.data.first['status'] = 'past_due'
        expect(Stripe::Customer).to receive(:retrieve).and_return(customer)
        expect_any_instance_of(Team).to receive(:inform!).with("Your subscription to Plan ($49.99) is past due. #{team.update_cc_text}")
        subject.send(:check_subscribed_teams!)
        expect(team.reload.past_due_informed_at).not_to be_nil
      end

      it 'does not re-notify past due subscription within 72 hours' do
        team.update_attributes!(past_due_informed_at: 1.hour.ago)
        customer.subscriptions.data.first['status'] = 'past_due'
        expect(Stripe::Customer).to receive(:retrieve).and_return(customer)
        expect_any_instance_of(Team).not_to receive(:inform!)
        subject.send(:check_subscribed_teams!)
      end

      it 'notifies past due subscription again after 72 hours' do
        team.update_attributes!(past_due_informed_at: 73.hours.ago)
        customer.subscriptions.data.first['status'] = 'past_due'
        expect(Stripe::Customer).to receive(:retrieve).and_return(customer)
        expect_any_instance_of(Team).to receive(:inform!).with("Your subscription to Plan ($49.99) is past due. #{team.update_cc_text}")
        subject.send(:check_subscribed_teams!)
      end

      it 'notifies canceled subscription' do
        customer.subscriptions.data.first['status'] = 'canceled'
        team.update_attributes!(past_due_informed_at: 1.hour.ago)
        expect(Stripe::Customer).to receive(:retrieve).and_return(customer)
        expect_any_instance_of(Team).to receive(:inform!).with('Your subscription to Plan ($49.99) was canceled and your team has been downgraded. Thank you for being a customer!')
        subject.send(:check_subscribed_teams!)
        expect(team.reload.subscribed?).to be false
        expect(team.reload.past_due_informed_at).to be_nil
      end

      it 'notifies no active subscriptions' do
        customer.subscriptions.data = []
        expect(Stripe::Customer).to receive(:retrieve).and_return(customer)
        expect_any_instance_of(Team).to receive(:inform!).with('Your subscription was canceled and your team has been downgraded. Thank you for being a customer!')
        subject.send(:check_subscribed_teams!)
        expect(team.reload.subscribed?).to be false
      end
    end
  end
end
