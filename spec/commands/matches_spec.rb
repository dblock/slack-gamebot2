# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Commands::Matches do
  include_context 'channel'

  shared_examples_for 'matches' do
    let(:user) { Fabricate(:user, channel: channel, user_name: 'username') }
    let(:singles_challenge) { Fabricate(:challenge, channel: channel, challengers: [user]) }
    let(:doubles_challenge) { Fabricate(:doubles_challenge, channel: channel, challengers: [user, Fabricate(:user)]) }

    context 'with many matches' do
      let!(:match0) { Fabricate(:match, channel: channel) }
      let!(:match1) { Fabricate(:match, channel: channel, challenge: doubles_challenge) }
      let!(:match2) { Fabricate(:match, channel: channel, challenge: doubles_challenge) }
      let!(:match3) { Fabricate(:match, channel: channel, challenge: doubles_challenge) }

      it 'displays top 10 matches' do
        expect_any_instance_of(Array).to receive(:take).with(10).and_call_original
        expect(message: '@gamebot matches', user: user, channel: doubles_challenge.channel).to respond_with_slack_message([
          "#{match1} 3 times",
          "#{match0} once"
        ].join("\n"))
      end

      it 'limits number of matches' do
        expect(message: '@gamebot matches 1', user: user, channel: doubles_challenge.channel).to respond_with_slack_message([
          "#{match1} 3 times"
        ].join("\n"))
      end

      it 'displays only matches for requested users' do
        expect(message: "@gamebot matches #{doubles_challenge.challenged.first.user_name}", user: user, channel: doubles_challenge.channel).to respond_with_slack_message(
          "#{match1} 3 times"
        )
      end

      it 'displays only matches for requested users with a limit' do
        another_challenge = Fabricate(:challenge, channel: channel, challengers: [doubles_challenge.challenged.first])
        Fabricate(:match, challenge: another_challenge)
        expect(message: "@gamebot matches #{doubles_challenge.challenged.first.user_name} 1", user: user, channel: doubles_challenge.channel).to respond_with_slack_message(
          "#{match1} 3 times"
        )
      end
    end

    context 'with a doubles match' do
      let!(:match) { Fabricate(:match, channel: channel, challenge: doubles_challenge) }

      it 'displays user matches' do
        expect(message: '@gamebot matches', user: user, channel: match.challenge.channel).to respond_with_slack_message(
          "#{match} once"
        )
      end
    end

    context 'with a singles match' do
      let!(:match) { Fabricate(:match, channel: channel, challenge: singles_challenge) }

      it 'displays user matches' do
        expect(message: '@gamebot matches', user: user, channel: match.challenge.channel).to respond_with_slack_message(
          "#{match} once"
        )
      end
    end

    context 'without matches' do
      it 'displays' do
        expect(message: '@gamebot matches', user: user, channel: channel).to respond_with_slack_message('No matches.')
      end
    end

    context 'matches in prior seasons' do
      let!(:match1) { Fabricate(:match, channel: channel, challenge: singles_challenge) }
      let!(:season) { Fabricate(:season, channel: channel) }
      let(:singles_challenge2) { Fabricate(:challenge, channel: channel, challengers: [user]) }
      let!(:match2) { Fabricate(:match, channel: channel, challenge: singles_challenge2) }

      it 'displays user matches in current season only' do
        expect(message: '@gamebot matches', user: user, channel: match2.challenge.channel).to respond_with_slack_message(
          "#{match2} once"
        )
      end
    end

    context 'lost to' do
      let(:loser) { Fabricate(:user, channel: channel, user_name: 'username') }
      let(:winner) { Fabricate(:user, channel: channel) }

      it 'a player' do
        expect(message: "@gamebot lost to #{winner.user_name}", user: loser.user_id, channel: channel).to respond_with_slack_message(
          "Match has been recorded! #{winner.user_name} defeated #{loser.user_name}."
        )
        expect(message: '@gamebot matches', user: loser.user_id, channel: channel).to respond_with_slack_message(
          "#{team.matches.first} once"
        )
      end
    end
  end

  it_behaves_like 'matches'

  context 'with another team' do
    let!(:team2) { Fabricate(:team) }
    let!(:channel2) { Fabricate(:channel, team: team2) }
    let!(:team2_match) { Fabricate(:match, channel: channel2, team: team2) }

    it_behaves_like 'matches'
  end
end
