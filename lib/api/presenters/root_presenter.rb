# frozen_string_literal: true

module SlackGamebot
  module Api
    module Presenters
      module RootPresenter
        include Roar::JSON::HAL
        include Roar::Hypermedia
        include Grape::Roar::Representer

        link :self do |opts|
          "#{base_url(opts)}/api/"
        end

        link :status do |opts|
          "#{base_url(opts)}/api/status"
        end

        link :users do |opts|
          {
            href: "#{base_url(opts)}/api/users/#{link_params(Api::Helpers::PaginationParameters::ALL, :channel_id, :captain)}",
            templated: true
          }
        end

        link :challenges do |opts|
          {
            href: "#{base_url(opts)}/api/challenges/#{link_params(Api::Helpers::PaginationParameters::ALL, :channel_id)}",
            templated: true
          }
        end

        link :matches do |opts|
          {
            href: "#{base_url(opts)}/api/matches/#{link_params(Api::Helpers::PaginationParameters::ALL, :channel_id)}",
            templated: true
          }
        end

        link :current_season do |opts|
          {
            href: "#{base_url(opts)}/api/seasons/current/{?channel_id}",
            templated: true
          }
        end

        link :seasons do |opts|
          {
            href: "#{base_url(opts)}/api/seasons/#{link_params(Api::Helpers::PaginationParameters::ALL, :channel_id)}",
            templated: true
          }
        end

        link :teams do |opts|
          {
            href: "#{base_url(opts)}/api/teams/#{link_params(Api::Helpers::PaginationParameters::ALL, :active)}",
            templated: true
          }
        end

        link :channels do |opts|
          {
            href: "#{base_url(opts)}/api/channels/#{link_params(Api::Helpers::PaginationParameters::ALL, :team_id)}",
            templated: true
          }
        end

        link :subscriptions do |opts|
          "#{base_url(opts)}/api/subscriptions"
        end

        link :credit_cards do |opts|
          "#{base_url(opts)}/api/credit_cards"
        end

        %i[challenge match user season team channel].each do |model|
          link model do |opts|
            {
              href: "#{base_url(opts)}/api/#{model.to_s.pluralize}/{id}",
              templated: true
            }
          end
        end

        private

        def base_url(opts)
          request = Grape::Request.new(opts[:env])
          request.base_url
        end

        def link_params(*args)
          "{?#{args.join(',')}}"
        end
      end
    end
  end
end
