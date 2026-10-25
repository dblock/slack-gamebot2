# frozen_string_literal: true

SlackRubyBotServer.configure do |config|
  config.server_pages do |pages|
    pages.cache_control = 'private, no-cache'
  end
  config.oauth_version = :v2
  config.oauth_scope = [
    'app_mentions:read',
    'channels:history',
    'channels:read',
    'chat:write',
    'groups:read',
    'im:history',
    'mpim:history',
    'mpim:read',
    'mpim:write',
    'users:read'
  ]
end
