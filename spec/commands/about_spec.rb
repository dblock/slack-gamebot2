# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Commands::About do
  context 'DM' do
    include_context 'dm'

    let(:admin) { Fabricate(:admin, team: team) }

    it 'about' do
      expect(message: 'about', channel: 'DM', user: admin.user_id).to respond_with_slack_message(SlackGamebot::INFO)
    end

    context 'with a new user' do
      let(:user_id) { 'U_new' }

      before do
        allow_any_instance_of(Slack::Web::Client).to receive(:users_info).with(user: user_id).and_return(
          Slack::Messages::Message.new('ok' => true, 'user' => { 'id' => user_id, 'name' => 'newuser', 'is_admin' => false, 'is_owner' => false })
        )
      end

      it 'creates an admin record' do
        expect do
          expect(message: 'about', channel: 'DM', user: user_id).to respond_with_slack_message(SlackGamebot::INFO)
        end.to change(Admin, :count).by(1)
      end

      it 'creates the admin record with is_admin false' do
        expect(message: 'about', channel: 'DM', user: user_id).to respond_with_slack_message(SlackGamebot::INFO)
        admin = Admin.find_by(user_id: user_id)
        expect(admin.user_name).to eq 'newuser'
        expect(admin.is_admin).to be false
        expect(admin.is_owner).to be false
      end
    end

    context 'subscription expiration' do
      before do
        team.update_attributes!(subscribed: false, created_at: 3.weeks.ago)
      end

      it 'responds with subscription expired' do
        expect(message: 'about', channel: 'DM').to respond_with_slack_message(
          "Your trial subscription has expired. Subscribe your team for $49.99 a year at https://gamebot2.playplay.io/subscribe?team_id=#{team.team_id}."
        )
      end
    end
  end

  context 'channel' do
    include_context 'user'

    it 'about' do
      expect(message: '@gamebot about', channel: channel, user: user).to respond_with_slack_message(SlackGamebot::INFO)
    end
  end
end
