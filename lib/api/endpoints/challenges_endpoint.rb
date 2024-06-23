module SlackGamebot
  module Api
    module Endpoints
      class ChallengesEndpoint < Grape::API
        format :json
        helpers Helpers::AuthHelpers
        helpers Helpers::CursorHelpers
        helpers Helpers::SortHelpers
        helpers Helpers::PaginationParameters

        namespace :challenges do
          desc 'Get a challenge.'
          params do
            requires :id, type: String, desc: 'Challenge ID.'
          end
          get ':id' do
            challenge = Challenge.find(params[:id]) || error!('Not Found', 404)
            authorize_channel! challenge.channel
            present challenge, with: SlackGamebot::Api::Presenters::ChallengePresenter
          end

          desc 'Get all the challenges.'
          params do
            requires :channel_id, type: String, desc: 'Channel ID.'
            use :pagination
          end
          sort Challenge::SORT_ORDERS
          get do
            channel = Channel.find(params[:channel_id]) || error!('Not Found', 404)
            authorize_channel! channel
            challenges = paginate_and_sort_by_cursor(channel.challenges, default_sort_order: '-_id')
            present challenges, with: SlackGamebot::Api::Presenters::ChallengesPresenter
          end
        end
      end
    end
  end
end
