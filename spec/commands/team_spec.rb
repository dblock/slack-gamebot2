require 'spec_helper'

describe SlackGamebot::Commands::Team do
  include_context 'channel'

  context 'with a captain' do
    let!(:user) { Fabricate(:user, channel: channel, user_name: 'username', captain: true) }

    it 'team' do
      expect(message: '@gamebot team', channel: channel).to respond_with_slack_message "Team #{team.team_id} #{channel.slack_mention}, captain username."
    end
  end

  context 'with two captains' do
    before do
      Array.new(2) { Fabricate(:user, channel: channel, captain: true) }
    end

    it 'team' do
      expect(message: '@gamebot team', channel: channel).to respond_with_slack_message "Team #{team.team_id} #{channel.slack_mention}, captains #{channel.captains.map(&:display_name).and}."
    end
  end
end
