# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Api::Endpoints::StatusEndpoint do
  include Api::Test::EndpointTest

  before do
    allow_any_instance_of(Team).to receive(:ping!).and_return(ok: 1)
  end

  context 'status' do
    subject do
      client.status
    end

    it 'returns a status' do
      expect(subject.teams_count).to eq 0
      expect(subject.channels_count).to eq 0
    end

    context 'with a team that is inactive' do
      let!(:team) { Fabricate(:team, api: true, active: false) }

      it 'returns a status' do
        expect(subject.teams_count).to eq 1
        expect(subject.active_teams_count).to eq 0
      end
    end

    context 'with a team that has an inactive account' do
      let!(:team) { Fabricate(:team, api: true, active: true) }

      before do
        expect_any_instance_of(Team).to receive(:ping!) { raise Slack::Web::Api::Errors::SlackError, 'account_inactive' }
      end

      it 'returns a status and deactivates team' do
        expect(subject.teams_count).to eq 1
        expect(subject.api_teams_count).to eq 1
        expect(subject.active_teams_count).to eq 0
        expect(team.reload.active).to be false
      end
    end

    context 'with a team with api off' do
      let!(:team) { Fabricate(:team, api: false) }

      it 'returns total counts anyway' do
        expect(subject.teams_count).to eq 1
        expect(subject.api_teams_count).to eq 0
      end
    end

    context 'with a channel with api off' do
      let!(:channel) { Fabricate(:channel, api: false) }

      it 'returns total counts anyway' do
        expect(subject.teams_count).to eq 1
        expect(subject.channels_count).to eq 1
        expect(subject.api_channels_count).to eq 0
      end
    end
  end
end
