require 'spec_helper'

describe SlackGamebot::Commands::Season do
  include_context 'user'

  shared_examples_for 'season' do
    context 'no seasons' do
      it 'seasons' do
        expect(message: '@gamebot season', user: user).to respond_with_slack_message "There're no seasons."
      end
    end

    context 'current season' do
      before do
        Fabricate(:match, channel: channel)
      end

      it 'returns current season' do
        current_season = Season.new(team: team, channel: channel)
        expect(message: '@gamebot season', user: user).to respond_with_slack_message current_season.to_s
      end

      context 'after reset' do
        before do
          Season.create!(team: team, channel: channel, created_by: user)
        end

        it 'returns current season' do
          expect(message: '@gamebot season', user: user).to respond_with_slack_message 'No matches have been recorded.'
        end
      end
    end
  end

  it_behaves_like 'season'

  context 'with another team' do
    let!(:team2) { Fabricate(:team) }
    let!(:channel2) { Fabricate(:channel, team: team2) }
    let!(:match2) { Fabricate(:match, channel: channel2, team: team2) }
    let!(:season2) { Fabricate(:season, channel: channel2, team: team2) }

    it_behaves_like 'season'
  end
end
