require 'spec_helper'

describe SlackGamebot::Commands::Hi do
  include_context 'team'

  it 'says hi' do
    expect(message: '@gamebot hi', user: 'user_not_in_channel', channel: 'DM').to respond_with_slack_message('Hi <@user_not_in_channel>!')
  end
end
