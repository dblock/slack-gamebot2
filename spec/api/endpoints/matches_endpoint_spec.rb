require 'spec_helper'

describe SlackGamebot::Api::Endpoints::MatchesEndpoint do
  include Api::Test::EndpointTest

  let!(:team) { Fabricate(:team, api: true) }
  let!(:channel) { Fabricate(:channel, team: team, api: true) }

  before do
    @cursor_params = { channel_id: channel.id.to_s }
  end

  it_behaves_like 'a cursor api', Match
  it_behaves_like 'a channel token api', Challenge

  context 'match' do
    let(:existing_match) { Fabricate(:match, team: team) }

    it 'returns a match' do
      match = client.match(id: existing_match.id)
      expect(match.id).to eq existing_match.id.to_s
      expect(match._links.self._url).to eq "http://example.org/api/matches/#{existing_match.id}"
      expect(match._links.channel._url).to eq "http://example.org/api/channels/#{existing_match.channel.id}"
    end
  end

  context 'match' do
    let(:existing_match) { Fabricate(:match) }

    it 'returns a match with links to challenge' do
      match = client.match(id: existing_match.id)
      expect(match.id).to eq existing_match.id.to_s
      expect(match._links.challenge._url).to eq "http://example.org/api/challenges/#{existing_match.challenge.id}"
      expect(match._links.winners._url).to eq existing_match.winners.map { |user| "http://example.org/api/users/#{user.id}" }
      expect(match._links.losers._url).to eq existing_match.losers.map { |user| "http://example.org/api/users/#{user.id}" }
    end
  end
end
