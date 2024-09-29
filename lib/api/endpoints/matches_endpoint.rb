# frozen_string_literal: true

module SlackGamebot
  module Api
    module Endpoints
      class MatchesEndpoint < Grape::API
        format :json
        helpers Helpers::AuthHelpers
        helpers Helpers::CursorHelpers
        helpers Helpers::SortHelpers
        helpers Helpers::PaginationParameters

        namespace :matches do
          desc 'Get a match.'
          params do
            requires :id, type: String, desc: 'Match ID.'
          end
          get ':id' do
            match = Match.find(params[:id]) || error!('Not Found', 404)
            authorize_channel! match.channel
            present match, with: SlackGamebot::Api::Presenters::MatchPresenter
          end

          desc 'Get all the matches.'
          params do
            requires :channel_id, type: String, desc: 'Channel ID.'
            use :pagination
          end
          sort Match::SORT_ORDERS
          get do
            channel = Channel.find(params[:channel_id]) || error!('Not Found', 404)
            authorize_channel! channel
            matches = paginate_and_sort_by_cursor(channel.matches, default_sort_order: '-_id')
            present matches, with: SlackGamebot::Api::Presenters::MatchesPresenter
          end
        end
      end
    end
  end
end
