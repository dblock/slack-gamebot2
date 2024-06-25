# frozen_string_literal: true

require 'spec_helper'

describe 'events/message' do
  include_context 'event'

  let(:team) { Fabricate(:team) }
  let(:channel) { Fabricate(:channel, team: team) }
  let(:user) { Fabricate(:user, channel: channel) }

  let(:event) do
    {
      type: 'message',
      team: team.team_id,
      user: user.user_id,
      channel: channel.channel_id,
      text: 'pp team'
    }
  end

  it 'ignores message' do
    expect_any_instance_of(Slack::Web::Client).not_to receive(:chat_postMessage)
    post '/api/slack/event', event_envelope
    expect(last_response.status).to eq 201
    expect(JSON.parse(last_response.body)).to eq('ok' => true)
  end

  context 'with a non matching alias' do
    before do
      channel.update_attributes!(aliases: ['xy'])
    end

    it 'does not match message' do
      expect_any_instance_of(Slack::Web::Client).not_to receive(:chat_postMessage)
      post '/api/slack/event', event_envelope
      expect(last_response.status).to eq 201
      expect(JSON.parse(last_response.body)).to eq('ok' => true)
    end
  end

  context 'with a matching alias' do
    before do
      channel.update_attributes!(aliases: %w[pp xy])
    end

    it 'matches message' do
      expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
        text: "Team #{team.team_id} #{channel.slack_mention}.", channel: channel.channel_id
      )
      post '/api/slack/event', event_envelope
      expect(last_response.status).to eq 201
      expect(JSON.parse(last_response.body)).to eq('ok' => true)
    end
  end
end
