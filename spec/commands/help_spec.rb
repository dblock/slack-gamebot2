# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Commands::Help do
  context 'subscribed team' do
    include_context 'subscribed team'

    it 'help' do
      expect(message: '@gamebot help', user: 'user_not_in_channel', channel: 'DM').to respond_with_slack_message(SlackGamebot::Commands::Help::HELP)
    end
  end

  context 'non-subscribed team' do
    include_context 'team'

    it 'help' do
      expect(message: '@gamebot help', user: 'user_not_in_channel', channel: 'DM').to respond_with_slack_message([SlackGamebot::Commands::Help::HELP, team.trial_message].join("\n"))
    end
  end
end
