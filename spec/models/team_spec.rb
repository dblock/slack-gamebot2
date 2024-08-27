require 'spec_helper'

describe Team do
  describe '#destroy' do
    let!(:team) { Fabricate(:team) }
    let!(:channel) { Fabricate(:channel, team: team) }
    let!(:match) { Fabricate(:match, channel: channel) }
    let!(:season) { Fabricate(:season, channel: channel) }

    it 'destroys dependent records' do
      expect(Team.count).to eq 1
      expect(User.count).to eq 2
      expect(Challenge.count).to eq 1
      expect(Match.count).to eq 1
      expect(Season.count).to eq 1
      expect do
        expect do
          expect do
            expect do
              expect do
                expect do
                  team.destroy
                end.to change(Team, :count).by(-1)
              end.to change(Channel, :count).by(-1)
            end.to change(User, :count).by(-2)
          end.to change(Challenge, :count).by(-1)
        end.to change(Match, :count).by(-1)
      end.to change(Season, :count).by(-1)
    end
  end

  describe '#purge!' do
    let!(:active_team) { Fabricate(:team) }
    let!(:inactive_team) { Fabricate(:team, active: false) }
    let!(:inactive_team_a_week_ago) { Fabricate(:team, updated_at: 1.week.ago, active: false) }
    let!(:inactive_team_two_weeks_ago) { Fabricate(:team, updated_at: 2.weeks.ago, active: false) }
    let!(:inactive_team_a_month_ago) { Fabricate(:team, updated_at: 1.month.ago, active: false) }

    it 'destroys teams inactive for two weeks' do
      expect do
        Team.purge!
      end.to change(Team, :count).by(-2)
      expect(Team.find(active_team.id)).to eq active_team
      expect(Team.find(inactive_team.id)).to eq inactive_team
      expect(Team.find(inactive_team_a_week_ago.id)).to eq inactive_team_a_week_ago
      expect(Team.find(inactive_team_two_weeks_ago.id)).to be_nil
      expect(Team.find(inactive_team_a_month_ago.id)).to be_nil
    end
  end

  describe '#dead? and #asleep?' do
    context 'default' do
      let(:team) { Fabricate(:team) }

      it 'false' do
        expect(team.asleep?).to be false
        expect(team.dead?).to be false
      end
    end

    context 'team created three weeks ago' do
      let(:team) { Fabricate(:team, created_at: 3.weeks.ago) }
      let(:channel) { Fabricate(:channel, team: team) }

      it 'dead=false' do
        expect(team.asleep?).to be true
        expect(team.dead?).to be false
      end

      context 'with a recent challenge' do
        let!(:challenge) { Fabricate(:challenge, channel: channel) }

        it 'false' do
          expect(team.asleep?).to be false
          expect(team.dead?).to be false
        end
      end

      context 'with a recent match' do
        let!(:match) { Fabricate(:match, channel: channel) }

        it 'false' do
          expect(team.asleep?).to be false
          expect(team.dead?).to be false
        end
      end

      context 'with a recent match lost to' do
        let!(:match) { Fabricate(:match_lost_to, channel: channel) }

        it 'false' do
          expect(team.asleep?).to be false
          expect(team.dead?).to be false
        end
      end

      context 'with an old challenge' do
        let!(:challenge) { Fabricate(:challenge, updated_at: 3.weeks.ago, channel: channel) }

        it 'true' do
          expect(team.asleep?).to be true
          expect(team.dead?).to be false
        end
      end
    end

    context 'team created over a month ago' do
      let(:team) { Fabricate(:team, created_at: 32.days.ago) }
      let(:channel) { Fabricate(:channel, team: team) }

      it 'dead=true' do
        expect(team.dead?).to be true
      end

      context 'with a recent challenge' do
        let!(:challenge) { Fabricate(:challenge, updated_at: 2.weeks.ago, channel: channel) }

        it 'true' do
          expect(team.dead?).to be false
        end
      end

      context 'with an old challenge' do
        let!(:challenge) { Fabricate(:challenge, updated_at: 5.weeks.ago, channel: channel) }

        it 'true' do
          expect(team.dead?).to be true
        end
      end
    end
  end

  context 'subscribed_at' do
    let(:subscribed_team) { Fabricate(:team, subscribed: true) }

    it 'is set when subscribed is set' do
      expect(subscribed_team.subscribed_at).not_to be_nil
    end
  end

  context 'subscribed states' do
    let(:today) { DateTime.parse('2018/7/15 12:42pm') }
    let(:subscribed_team) { Fabricate(:team, subscribed: true) }
    let(:team_created_today) { Fabricate(:team, created_at: today) }
    let(:team_created_1_week_ago) { Fabricate(:team, created_at: (today - 1.week)) }
    let(:team_created_3_weeks_ago) { Fabricate(:team, created_at: (today - 3.weeks)) }

    before do
      Timecop.travel(today + 1.day)
    end

    after do
      Timecop.return
    end

    it 'subscription_expired?' do
      expect(subscribed_team.subscription_expired?).to be false
      expect(team_created_1_week_ago.subscription_expired?).to be false
      expect(team_created_3_weeks_ago.subscription_expired?).to be true
    end

    it 'trial_ends_at' do
      expect { subscribed_team.trial_ends_at }.to raise_error 'Team is subscribed.'
      expect(team_created_today.trial_ends_at).to eq team_created_today.created_at + 2.weeks
      expect(team_created_1_week_ago.trial_ends_at).to eq team_created_1_week_ago.created_at + 2.weeks
      expect(team_created_3_weeks_ago.trial_ends_at).to eq team_created_3_weeks_ago.created_at + 2.weeks
    end

    it 'remaining_trial_days' do
      expect { subscribed_team.remaining_trial_days }.to raise_error 'Team is subscribed.'
      expect(team_created_today.remaining_trial_days).to eq 13
      expect(team_created_1_week_ago.remaining_trial_days).to eq 6
      expect(team_created_3_weeks_ago.remaining_trial_days).to eq 0
    end

    describe '#inform_trial!' do
      it 'subscribed' do
        expect(subscribed_team).not_to receive(:inform!)
        subscribed_team.inform_trial!
      end

      it '1 week ago' do
        expect(team_created_1_week_ago).to receive(:inform!).with(
          "Your trial subscription expires in 6 days. #{team_created_1_week_ago.subscribe_text}"
        )
        team_created_1_week_ago.inform_trial!
      end

      it 'expired' do
        expect(team_created_3_weeks_ago).not_to receive(:inform!)
        team_created_3_weeks_ago.inform_trial!
      end

      it 'informs once' do
        expect(team_created_1_week_ago).to receive(:inform!).once
        2.times { team_created_1_week_ago.inform_trial! }
      end
    end
  end

  describe '#inform!' do
    let(:team) { Fabricate(:team) }
    let!(:not_app_home_channel) { Fabricate(:channel, team: team) }
    let!(:app_home_channel) { Fabricate(:channel, team: team, is_app_home: true) }

    before do
      team.bot_user_id = 'bot_user_id'
    end

    it 'sends message to all channels', vcr: { cassette_name: 'users_conversations' } do
      expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).exactly(26).times.and_return('ts' => '1503435956.000247')
      team.inform!(message: 'message')
    end
  end

  describe '#activated' do
    pending 'DMs installing user when activated'
  end

  describe '#find_create_or_update_channel_by_channel_id!' do
    let(:team) { Fabricate(:team) }

    before do
      allow(team.slack_client).to receive(:conversations_info)
    end

    it 'creates a new public channel' do
      expect do
        channel = team.find_create_or_update_channel_by_channel_id!('C123', 'U123')
        expect(channel.channel_id).to eq 'C123'
        expect(channel.inviter_id).to eq 'U123'
        expect(channel.is_group).to be false
        expect(channel.is_app_home).to be false
      end.to change(Channel, :count).by(1)
    end

    {
      elo: 10,
      unbalanced: true,
      leaderboard_max: 5,
      gifs: false,
      aliases: %w[ping pong]
    }.each_pair do |k, v|
      context "with #{k}=#{v}" do
        before do
          team.update_attributes!(k => v)
        end

        it "inherits #{v}" do
          expect do
            channel = team.find_create_or_update_channel_by_channel_id!('C123', 'U123')
            expect(channel.channel_id).to eq 'C123'
            expect(channel.inviter_id).to eq 'U123'
            expect(channel.send(k)).to eq v
          end.to change(Channel, :count).by(1)
        end
      end
    end

    it 'does not create a new channel for DMs' do
      expect do
        channel = team.find_create_or_update_channel_by_channel_id!('D123', 'U123')
        expect(channel).to be_nil
      end.not_to change(Channel, :count)
    end

    it 'does not create a new IM channel' do
      expect do
        expect(team.slack_client).to receive(:conversations_info).and_return(
          Hashie::Mash.new(
            channel: {
              is_im: true
            }
          )
        )
        channel = team.find_create_or_update_channel_by_channel_id!('C1234', 'U123')
        expect(channel).to be_nil
      end.not_to change(Channel, :count)
    end

    it 'create a new MPIM channel' do
      expect do
        expect(team.slack_client).to receive(:conversations_info).and_return(
          Hashie::Mash.new(
            channel: {
              is_mpim: true
            }
          )
        )
        channel = team.find_create_or_update_channel_by_channel_id!('C1234', 'U123')
        expect(channel).not_to be_nil
      end.to change(Channel, :count).by(1)
    end

    it 'create a new private group channel' do
      expect do
        expect(team.slack_client).to receive(:conversations_info).and_return(
          Hashie::Mash.new(
            channel: {
              is_group: true
            }
          )
        )
        channel = team.find_create_or_update_channel_by_channel_id!('C1234', 'U123')
        expect(channel).not_to be_nil
        expect(channel.is_group).to be true
        expect(channel.is_app_home).to be false
      end.to change(Channel, :count).by(1)
    end

    context 'with an existing channel' do
      let!(:channel) { Fabricate(:channel, team: team) }

      it 'reuses an existing channel' do
        expect do
          existing_channel = team.find_create_or_update_channel_by_channel_id!(channel.channel_id, 'U123')
          expect(existing_channel).to eq channel
        end.not_to change(Channel, :count)
      end
    end
  end

  describe '#find_create_or_update_user_in_channel_by_slack_id!', vcr: { cassette_name: 'users_info' } do
    let(:team) { Fabricate(:team) }

    before do
      allow(team.slack_client).to receive(:conversations_info)
    end

    it 'creates a new channel and user' do
      expect do
        expect do
          user = team.find_create_or_update_user_in_channel_by_slack_id!('C123', 'U123')
          expect(user.user_id).to eq 'U123'
          expect(user.channel.channel_id).to eq 'C123'
        end.to change(Channel, :count).by(1)
      end.to change(User, :count).by(1)
    end

    it 'does not create a new channel or user for a DM' do
      expect do
        expect do
          user_id = team.find_create_or_update_user_in_channel_by_slack_id!('D123', 'U123')
          expect(user_id).to eq 'U123'
        end.not_to change(Channel, :count)
      end.not_to change(User, :count)
    end

    context 'with an existing channel' do
      let!(:channel) { Fabricate(:channel, team: team) }

      it 'reuses an existing team and creates a new user' do
        expect do
          expect do
            user = team.find_create_or_update_user_in_channel_by_slack_id!(channel.channel_id, 'U123')
            expect(user.user_id).to eq 'U123'
          end.not_to change(Channel, :count)
        end.to change(User, :count).by(1)
      end

      context 'with an existing team and user' do
        let!(:user) { Fabricate(:user, channel: channel) }

        it 'reuses an existing channel and creates a new user' do
          expect do
            expect do
              found_user = team.find_create_or_update_user_in_channel_by_slack_id!(channel.channel_id, user.user_id)
              expect(found_user.user_id).to eq user.user_id
            end.not_to change(Channel, :count)
          end.not_to change(User, :count)
        end
      end
    end
  end

  describe '#join_channel!' do
    let!(:team) { Fabricate(:team) }

    before do
      allow(team.slack_client).to receive(:conversations_info).and_return(
        Hashie::Mash.new(
          channel: {
            is_group: true
          }
        )
      )
    end

    it 'creates a new private channel' do
      expect do
        channel = team.join_channel!('C123', 'U123')
        expect(channel).not_to be_nil
        expect(channel.channel_id).to eq 'C123'
        expect(channel.inviter_id).to eq 'U123'
        expect(channel.is_group).to be true
        expect(channel.is_app_home).to be false
      end.to change(Channel, :count).by(1)
    end

    context 'with a previously joined team' do
      let(:channel) { team.join_channel!('C123', 'U123') }

      context 'after leaving a team' do
        before do
          team.leave_channel!(channel.channel_id)
        end

        context 'after rejoining the channel' do
          let!(:rejoined_channel) { team.join_channel!(channel.channel_id, 'U456') }

          it 're-enables channel' do
            rejoined_channel.reload
            expect(rejoined_channel.enabled).to be true
            expect(rejoined_channel.inviter_id).to eq 'U456'
            expect(rejoined_channel.is_group).to be true
            expect(rejoined_channel.is_app_home).to be false
          end
        end
      end
    end

    context 'with an existing channel' do
      let!(:channel) { Fabricate(:channel, team: team) }

      it 'creates a new channel' do
        expect do
          channel = team.join_channel!('C123', 'U123')
          expect(channel).not_to be_nil
          expect(channel.channel_id).to eq 'C123'
          expect(channel.inviter_id).to eq 'U123'
          expect(channel.is_group).to be true
        end.to change(Channel, :count).by(1)
      end

      it 'creates a new channel for a different team' do
        expect do
          team2 = Fabricate(:team)
          expect(team2.slack_client).to receive(:conversations_info)
          channel2 = team2.join_channel!(channel.channel_id, 'U123')
          expect(channel2).not_to be_nil
          expect(channel2.team).to eq team2
          expect(channel2.inviter_id).to eq 'U123'
          expect(channel2.is_group).to be false
        end.to change(Channel, :count).by(1)
      end

      it 'updates an existing channel' do
        expect do
          channel2 = team.join_channel!(channel.channel_id, 'U123')
          expect(channel2).not_to be_nil
          expect(channel2).to eq channel
          expect(channel2.team).to eq team
          expect(channel2.inviter_id).to eq 'U123'
          expect(channel2.is_group).to be true
        end.not_to change(Channel, :count)
      end
    end
  end

  describe '#leave_channel!' do
    let(:team) { Fabricate(:team) }

    it 'ignores a team the bot is not a member of' do
      expect do
        expect(team.leave_channel!('C123')).to be false
      end.not_to change(Channel, :count)
    end

    context 'with an existing team' do
      let!(:channel) { Fabricate(:channel, team: team) }

      context 'after leaving a team' do
        before do
          team.leave_channel!(channel.channel_id)
        end

        it 'disables channel' do
          channel.reload
          expect(channel.enabled).to be false
        end
      end

      it 'can leave an existing team twice' do
        expect do
          2.times { expect(team.leave_channel!(channel.channel_id)).to eq channel }
        end.not_to change(Channel, :count)
      end

      it 'does not leave team for the wrong team' do
        team2 = Fabricate(:team)
        expect(team2.leave_channel!(channel.channel_id)).to be false
      end
    end
  end

  describe 'bot_mention' do
    context 'without bot_user_id' do
      let(:team) { Fabricate(:team, bot_user_id: nil) }

      it 'is a slack mention' do
        expect(team.bot_mention).to be_nil
      end
    end

    context 'with bot_user_id' do
      let(:team) { Fabricate(:team, bot_user_id: 'bot_id') }

      before do
        allow_any_instance_of(Team).to receive(:inform!)
      end

      it 'is a slack mention' do
        expect(team.bot_mention).to eq '<@bot_id>'
      end
    end
  end

  describe '#find_create_or_updae_admin_by_slack_id!', vcr: { cassette_name: 'users_info' } do
    let(:team) { Fabricate(:team) }

    context 'without a user' do
      it 'creates an admin' do
        expect do
          admin = team.find_create_or_updae_admin_by_slack_id!('U42')
          expect(admin).not_to be_nil
          expect(admin.user_id).to eq 'U42'
          expect(admin.user_name).to eq 'username'
        end.to change(Admin, :count).by(1)
      end
    end

    context 'with an admin' do
      let!(:admin) { Fabricate(:admin, team: team) }

      it 'creates another user' do
        expect do
          team.find_create_or_updae_admin_by_slack_id!('U42')
        end.to change(Admin, :count).by(1)
      end

      it 'updates the username of the existing user' do
        expect do
          team.find_create_or_updae_admin_by_slack_id!(admin.user_id)
        end.not_to change(Admin, :count)
        expect(admin.reload.user_name).to eq 'username'
      end
    end
  end
end
