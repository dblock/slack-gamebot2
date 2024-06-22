module SlackGamebot
  module Api
    module Endpoints
      # https://github.com/slack-ruby/slack-ruby-bot-server-events/blob/0f21bf0ca3103b6a1e311eba6073ab615a3340e5/lib/slack-ruby-bot-server/api/endpoints.rb#L22
      class SlackEndpoint < Grape::API
        namespace :slack do
          format :json

          before do
            ::Slack::Events::Request.new(
              request,
              signing_secret: SlackRubyBotServer::Events.config.signing_secret,
              signature_expires_in: SlackRubyBotServer::Events.config.signature_expires_in
            ).verify!
          rescue ::Slack::Events::Request::TimestampExpired
            error!('Invalid Signature', 403)
          end

          mount SlackRubyBotServer::Events::Api::Endpoints::Slack::CommandsEndpoint
          mount SlackRubyBotServer::Events::Api::Endpoints::Slack::ActionsEndpoint
          mount SlackRubyBotServer::Events::Api::Endpoints::Slack::EventsEndpoint
        end
      end
    end
  end
end
