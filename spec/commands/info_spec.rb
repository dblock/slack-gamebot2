# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Commands::Info do
  include_context 'team'

  it 'info' do
    expect(message: '@gamebot info', user: 'user_not_in_channel', channel: 'DM').to respond_with_slack_message(SlackGamebot::INFO)
  end
end
