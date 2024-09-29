# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Api::Endpoints::SeasonsEndpoint do
  include Api::Test::EndpointTest

  let!(:team) { Fabricate(:team, api: true, api_token: 'token') }
  let!(:channel) { Fabricate(:channel, team: team, api: true) }

  before do
    @cursor_params = { channel_id: channel.id.to_s }
  end

  it_behaves_like 'a cursor api', Season
  it_behaves_like 'a channel token api', Challenge

  context 'season' do
    let(:existing_season) { Fabricate(:season) }

    it 'returns a season' do
      season = client.season(id: existing_season.id)
      expect(season.id).to eq existing_season.id.to_s
      expect(season._links.self._url).to eq "http://example.org/api/seasons/#{existing_season.id}"
      expect(season._links.channel._url).to eq "http://example.org/api/channels/#{existing_season.channel.id}"
    end
  end

  context 'current season' do
    before do
      Fabricate(:match)
    end

    it 'returns the current season' do
      season = client.current_season(channel_id: channel.id.to_s)
      expect(season.id).to eq 'current'
      expect(season._links.self._url).to eq 'http://example.org/api/seasons/current'
    end
  end
end
