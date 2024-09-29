# frozen_string_literal: true

module SlackGamebot
  module Api
    module Endpoints
      class RootEndpoint < Grape::API
        include Api::Helpers::ErrorHelpers

        prefix :api
        format :json
        formatter :json, Grape::Formatter::Roar
        get do
          present self, with: SlackGamebot::Api::Presenters::RootPresenter
        end

        mount SlackGamebot::Api::Endpoints::StatusEndpoint
        mount SlackGamebot::Api::Endpoints::TeamsEndpoint
        mount SlackGamebot::Api::Endpoints::ChannelsEndpoint
        mount SlackGamebot::Api::Endpoints::UsersEndpoint
        mount SlackGamebot::Api::Endpoints::ChallengesEndpoint
        mount SlackGamebot::Api::Endpoints::MatchesEndpoint
        mount SlackGamebot::Api::Endpoints::SeasonsEndpoint
        mount SlackGamebot::Api::Endpoints::SubscriptionsEndpoint
        mount SlackGamebot::Api::Endpoints::CreditCardsEndpoint
        mount SlackGamebot::Api::Endpoints::SlackEndpoint

        add_swagger_documentation
      end
    end
  end
end
