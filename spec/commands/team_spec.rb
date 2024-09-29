# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Commands::Team do
  include_context 'user'

  context 'with a captain' do
    let!(:user) { Fabricate(:user, channel: channel, user_name: 'username', captain: true) }

    it 'team' do
      expect(message: '@gamebot team', channel: channel, user: user).to respond_with_slack_message "Team #{team.team_id} #{channel.slack_mention}, captain username."
    end

    context 'gifs' do
      before do
        allow(Giphy).to receive(:random).with('team').and_return('team_gif')
      end

      context 'with gifs enabled' do
        before do
          channel.update_attributes!(gifs: true)
        end

        it 'sends gif' do
          expect(message: '@gamebot team', channel: channel, user: user).to respond_with_slack_message(text: "Team #{team.team_id} #{channel.slack_mention}, captain username.\nteam_gif", channel: channel.channel_id)
        end
      end

      context 'with gifs disabled' do
        before do
          channel.update_attributes!(gifs: false)
        end

        it 'does not send gif' do
          expect(message: '@gamebot team', channel: channel, user: user).to respond_with_slack_message(text: "Team #{team.team_id} #{channel.slack_mention}, captain username.", channel: channel.channel_id)
        end
      end
    end
  end

  context 'with two captains' do
    before do
      Array.new(2) { Fabricate(:user, channel: channel, captain: true) }
    end

    it 'team' do
      expect(message: '@gamebot team', channel: channel, user: user).to respond_with_slack_message "Team #{team.team_id} #{channel.slack_mention}, captains #{channel.captains.map(&:display_name).and}."
    end
  end
end
