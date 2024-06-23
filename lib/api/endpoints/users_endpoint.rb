module SlackGamebot
  module Api
    module Endpoints
      class UsersEndpoint < Grape::API
        format :json
        helpers Helpers::AuthHelpers
        helpers Helpers::CursorHelpers
        helpers Helpers::SortHelpers
        helpers Helpers::PaginationParameters

        namespace :users do
          desc 'Get a user.'
          params do
            requires :id, type: String, desc: 'User ID.'
          end
          get ':id' do
            user = User.find(params[:id]) || error!('Not Found', 404)
            authorize_channel! user.channel
            present user, with: SlackGamebot::Api::Presenters::UserPresenter
          end

          desc 'Get all the users.'
          params do
            requires :channel_id, type: String, desc: 'Channel ID.'
            optional :captain, type: Boolean
            use :pagination
          end
          sort User::SORT_ORDERS
          get do
            channel = Channel.find(params[:channel_id]) || error!('Not Found', 404)
            authorize_channel! channel
            query = channel.users
            query = query.captains if params[:captain]
            users = paginate_and_sort_by_cursor(query, default_sort_order: '-elo')
            present users, with: SlackGamebot::Api::Presenters::UsersPresenter
          end
        end
      end
    end
  end
end
