# frozen_string_literal: true

require 'spec_helper'

describe 'Add to Slack', :js, type: :feature do
  before do
    ENV['SLACK_CLIENT_ID'] = 'client_id'
    ENV['SLACK_CLIENT_SECRET'] = 'client_secret'
  end

  after do
    ENV.delete 'SLACK_CLIENT_ID'
    ENV.delete 'SLACK_CLIENT_SECRET'
  end

  it 'registers a team' do
    allow_any_instance_of(Team).to receive(:ping!).and_return(ok: true)
    expect(SlackRubyBotServer::Service.instance).to receive(:start!)
    oauth_access = {
      'access_token' => 'token',
      'token_type' => 'bot',
      'bot_user_id' => 'bot_user_id',
      'team' => {
        'id' => 'team_id',
        'name' => 'team_name'
      },
      'authed_user' => {
        'id' => 'activated_user_id',
        'access_token' => 'user_token',
        'token_type' => 'user'
      }
    }
    allow_any_instance_of(Slack::Web::Client).to receive(:oauth_v2_access).with(hash_including(code: 'code')).and_return(oauth_access)
    allow_any_instance_of(Slack::Web::Client).to receive(:conversations_open).with(
      users: 'activated_user_id'
    ).and_return(
      'channel' => {
        'id' => 'C1'
      }
    )
    expect_any_instance_of(Team).to receive(:inform!).with(Team::INSTALLED_TEXT)
    expect do
      visit '/?code=code'
      expect(page.find_by_id('messages')).to have_content 'Team successfully registered!'
    end.to change(Team, :count).by(1)
  end
end
