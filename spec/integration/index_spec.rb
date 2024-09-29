# frozen_string_literal: true

require 'spec_helper'

describe 'index.html', :js, type: :feature do
  before do
    visit '/'
  end

  it 'includes a link to add to slack with the client id' do
    expect(title).to eq('PlayPlay.io - Leaderboard Bot for Slack')
    expect(first('a[class=add-to-slack]')['href']).to eq "https://slack.com/oauth/v2/authorize?scope=#{SlackRubyBotServer::Config.oauth_scope_s}&client_id=#{ENV.fetch('SLACK_CLIENT_ID', nil)}"
  end
end
