module SlackGamebot
  module Api
    module Helpers
      module AuthHelpers
        def authorize_channel!(channel)
          access_token = headers['X-Access-Token']
          return if channel.api? && channel.api_token == access_token
          return if !access_token.blank? && access_token == channel.team.api_token && channel.team.api?

          error!('Access Denied', 401)
        end

        def authorize_team!(team)
          access_token = headers['X-Access-Token']
          return if team.api? && team.api_token == access_token

          error!('Access Denied', 401)
        end
      end
    end
  end
end
