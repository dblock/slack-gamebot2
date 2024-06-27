require 'spec_helper'

describe SlackGamebot::Commands::About do
  context 'DM' do
    include_context 'dm'

    let(:admin) { Fabricate(:admin, team: team) }

    it 'about' do
      expect(message: 'about', channel: 'DM', user: admin.user_id).to respond_with_slack_message(SlackGamebot::INFO)
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
