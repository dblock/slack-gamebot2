# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Commands::Seasons do
  include_context 'channel'

  shared_examples_for 'seasons' do
    context 'no seasons' do
      it 'seasons' do
        expect(message: '@gamebot seasons', channel: channel).to respond_with_slack_message "There're no seasons."
      end
    end

    context 'one season' do
      before do
        Array.new(2) { Fabricate(:match, channel: channel, team: team) }
        challenge = Fabricate(:challenge, channel: channel, challengers: [team.users.asc(:_id).first], challenged: [team.users.asc(:_id).last])
        Fabricate(:match, channel: channel, challenge: challenge)
      end

      let!(:season) { Fabricate(:season, channel: channel, team: team) }

      it 'seasons' do
        expect(message: '@gamebot seasons', channel: channel).to respond_with_slack_message season.to_s
      end
    end

    context 'two seasons' do
      let!(:seasons) do
        Array.new(2) do |n|
          team.users.all.destroy
          Array.new(n + 1) { Fabricate(:match, channel: channel, team: team) }
          challenge = Fabricate(:challenge, channel: channel, challengers: [team.users.asc(:_id).first], challenged: [team.users.asc(:_id).last])
          Fabricate(:match, channel: channel, challenge: challenge)
          Fabricate(:season, channel: channel)
        end
      end

      it 'returns past seasons and current season' do
        expect(message: '@gamebot seasons', channel: channel).to respond_with_slack_message seasons.reverse.map(&:to_s).join("\n")
      end
    end

    context 'current season' do
      before do
        Array.new(2) { Fabricate(:match, channel: channel) }
      end

      it 'returns past seasons and current season' do
        current_season = Season.new(team: team, channel: channel)
        expect(message: '@gamebot seasons', channel: channel).to respond_with_slack_message current_season.to_s
      end
    end

    context 'current and past season' do
      let!(:season1) do
        Array.new(2) { Fabricate(:match, channel: channel) }
        challenge = Fabricate(:challenge, channel: channel, challengers: [team.users.asc(:_id).first], challenged: [team.users.asc(:_id).last])
        Fabricate(:match, channel: channel, challenge: challenge)
        Fabricate(:season, channel: channel)
      end
      let!(:current_season) do
        Array.new(2) { Fabricate(:match, channel: channel) }
        Season.new(team: team, channel: channel)
      end

      it 'returns past seasons and current season' do
        expect(message: '@gamebot seasons', channel: channel).to respond_with_slack_message [current_season, season1].map(&:to_s).join("\n")
      end
    end
  end

  context 'subscribed team' do
    let!(:team) { Fabricate(:team, subscribed: true) }

    it_behaves_like 'seasons'

    context 'with another team' do
      let!(:team2) { Fabricate(:team) }
      let!(:channel2) { Fabricate(:channel, team: team2) }
      let!(:match2) { Fabricate(:match, channel: channel2, team: team2) }
      let!(:season2) { Fabricate(:season, channel: channel2, team: team2) }

      it_behaves_like 'seasons'
    end
  end
end
