# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Api::Endpoints::ChannelsEndpoint do
  include Api::Test::EndpointTest

  let!(:team) { Fabricate(:team, api: true, api_token: 'token') }

  before do
    @cursor_params = { team_id: team.id.to_s }
  end

  it_behaves_like 'a cursor api', Channel

  context 'channel' do
    let(:existing_channel) { Fabricate(:channel, team: team) }

    it 'returns a channel' do
      channel = client.channel(id: existing_channel.id)
      expect(channel.id).to eq existing_channel.id.to_s
      expect(channel.channel_id).to eq existing_channel.channel_id
      expect(channel._links.self._url).to eq "http://example.org/api/channels/#{existing_channel.id}"
      expect(channel._links.team._url).to eq "http://example.org/api/teams/#{team.id}"
      expect(channel._links.users._url).to eq "http://example.org/api/users?channel_id=#{existing_channel.id}"
      expect(channel._links.challenges._url).to eq "http://example.org/api/challenges?channel_id=#{existing_channel.id}"
      expect(channel._links.matches._url).to eq "http://example.org/api/matches?channel_id=#{existing_channel.id}"
      expect(channel._links.seasons._url).to eq "http://example.org/api/seasons?channel_id=#{existing_channel.id}"
    end

    context 'a channel with a team api without a token' do
      before do
        team.update_attributes!(api: true, api_token: nil)
      end

      it 'is not returned without an X-Access-Token header' do
        expect { client.channel(id: existing_channel.id).id }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Access Denied'
        end
      end

      it 'is not returned with X-Access-Token header' do
        client.headers.update('X-Access-Token' => 'token')
        expect { client.channel(id: existing_channel.id).id }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Access Denied'
        end
      end
    end

    context 'a channel with a team api set to false' do
      before do
        team.update_attributes!(api: false, api_token: 'token')
        client.headers.update('X-Access-Token' => team.api_token)
      end

      it 'is not returned' do
        expect { client.channel(id: existing_channel.id).id }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Access Denied'
        end
      end
    end

    context 'a channel with api set to false' do
      before do
        existing_channel.update_attributes!(api: false)
      end

      it 'is not returned' do
        expect { client.channel(id: existing_channel.id).id }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Access Denied'
        end
      end
    end
  end

  context 'channels' do
    let!(:channel1) { Fabricate(:channel, team: team, api: true) }
    let!(:channel2) { Fabricate(:channel, team: team, api: false) }

    context 'with team api enabled' do
      before do
        team.update_attributes!(api: true, api_token: 'token')
      end

      it 'returns channels' do
        channels = client.channels(team_id: team.id)
        expect(channels.map(&:id).sort).to eq [channel1, channel2].map(&:id).map(&:to_s).sort
      end
    end

    context 'with team api disabled' do
      before do
        team.update_attributes!(api: false)
      end

      it 'is not returned' do
        expect { client.send(:channels, @cursor_params).resource }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Access Denied'
        end
      end
    end

    context 'with a team api token' do
      before do
        team.update_attributes!(api: true, api_token: 'token')
      end

      it 'is not returned without a team api token' do
        client.headers.delete('X-Access-Token')
        expect { client.send(:channels, @cursor_params).resource }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Access Denied'
        end
      end

      it 'is not returned with the wrong team api token' do
        client.headers.update('X-Access-Token' => 'invalid')
        expect { client.send(:channels, @cursor_params).resource }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Access Denied'
        end
      end

      it 'is returned with the correct team api token' do
        client.headers.update('X-Access-Token' => team.api_token)
        returned_intances = client.send(:channels, @cursor_params)
        expect(returned_intances.count).to eq 2
      end
    end
  end
end
