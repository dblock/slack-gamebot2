module SlackGamebot
  module Api
    module Endpoints
      class RootEndpoint < Grape::API
        include Api::Helpers::ErrorHelpers

        mount SlackGamebot::Api::Endpoints::SlackEndpoint
        mount SlackGamebot::Api::Endpoints::ApiEndpoint
      end
    end
  end
end
