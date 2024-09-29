# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Api::Endpoints::ChallengesEndpoint do
  include Api::Test::EndpointTest

  let!(:team) { Fabricate(:team, api: true, api_token: 'token') }
  let!(:channel) { Fabricate(:channel, team: team, api: true) }

  before do
    @cursor_params = { channel_id: channel.id.to_s }
  end

  it_behaves_like 'a cursor api', Challenge
  it_behaves_like 'a channel token api', Challenge

  context 'challenge' do
    let(:existing_challenge) { Fabricate(:challenge) }

    it 'returns a challenge' do
      challenge = client.challenge(id: existing_challenge.id)
      expect(challenge.id).to eq existing_challenge.id.to_s
      expect(challenge._links.self._url).to eq "http://example.org/api/challenges/#{existing_challenge.id}"
      expect(challenge._links.channel._url).to eq "http://example.org/api/channels/#{existing_challenge.channel.id}"
    end

    context 'with a team api token' do
      before do
        client.headers.update('X-Access-Token' => 'token')
        existing_challenge.channel.team.update_attributes!(api_token: 'token')
      end

      it 'returns a round using a team API token' do
        challenge = client.challenge(id: existing_challenge.id)
        expect(challenge.id).to eq challenge.id.to_s
      end
    end
  end

  context 'doubles challenge' do
    let(:existing_challenge) { Fabricate(:doubles_challenge) }

    before do
      existing_challenge.accept!(existing_challenge.challenged.first)
      existing_challenge.lose!(existing_challenge.challengers.first)
    end

    it 'returns a challenge with links to challengers, challenged and played match' do
      challenge = client.challenge(id: existing_challenge.id)
      expect(challenge.id).to eq existing_challenge.id.to_s
      expect(challenge._links.challengers._url).to eq existing_challenge.challengers.map { |user| "http://example.org/api/users/#{user.id}" }
      expect(challenge._links.challenged._url).to eq existing_challenge.challenged.map { |user| "http://example.org/api/users/#{user.id}" }
      expect(challenge._links.match._url).to eq "http://example.org/api/matches/#{existing_challenge.match.id}"
    end
  end
end
