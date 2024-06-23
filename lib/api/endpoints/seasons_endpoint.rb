module SlackGamebot
  module Api
    module Endpoints
      class SeasonsEndpoint < Grape::API
        format :json
        helpers Helpers::AuthHelpers
        helpers Helpers::CursorHelpers
        helpers Helpers::SortHelpers
        helpers Helpers::PaginationParameters

        namespace :seasons do
          desc 'Get current season.'
          params do
            requires :channel_id, type: String, desc: 'Channel ID.'
          end
          get 'current' do
            channel = Channel.find(params[:channel_id]) || error!('Not Found', 404)
            authorize_channel! channel
            present Season.new(channel: channel), with: SlackGamebot::Api::Presenters::SeasonPresenter
          end

          desc 'Get a season.'
          params do
            requires :id, type: String, desc: 'Season ID.'
          end
          get ':id' do
            season = Season.find(params[:id]) || error!('Not Found', 404)
            authorize_channel! season.channel
            present season, with: SlackGamebot::Api::Presenters::SeasonPresenter
          end

          desc 'Get all past seasons.'
          params do
            requires :channel_id, type: String, desc: 'Channel ID.'
            use :pagination
          end
          sort Season::SORT_ORDERS
          get do
            channel = Channel.find(params[:channel_id]) || error!('Not Found', 404)
            authorize_channel! channel
            seasons = paginate_and_sort_by_cursor(channel.seasons, default_sort_order: '-_id')
            present seasons, with: SlackGamebot::Api::Presenters::SeasonsPresenter
          end
        end
      end
    end
  end
end
