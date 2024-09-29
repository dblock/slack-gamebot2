# frozen_string_literal: true

module SlackGamebot
  module Api
    module Presenters
      module ChannelPresenter
        include Roar::JSON::HAL
        include Roar::Hypermedia
        include Grape::Roar::Representer

        property :id, type: String, desc: 'Channel ID.'
        property :enabled, type: Grape::API::Boolean, desc: 'Channel is enabled.'
        property :gifs, type: ::Grape::API::Boolean, desc: 'Team loves animated GIFs.'
        property :aliases, type: Array, desc: 'Bot aliases.'
        property :channel_id, type: String, desc: 'Slack channel ID.'
        property :elo, type: Integer, desc: 'Base elo.'
        property :unbalanced, type: ::Grape::API::Boolean, desc: 'Permits unbalanced challenges.'
        property :created_at, type: DateTime, desc: 'Date/time when the channel was created.'
        property :updated_at, type: DateTime, desc: 'Date/time when the channel was updated.'

        link :team do |opts|
          request = Grape::Request.new(opts[:env])
          "#{request.base_url}/api/teams/#{team.id}"
        end

        link :users do |opts|
          request = Grape::Request.new(opts[:env])
          "#{request.base_url}/api/users?channel_id=#{id}"
        end

        link :captains do |opts|
          request = Grape::Request.new(opts[:env])
          "#{request.base_url}/api/users?team_id=#{represented.id}&captain=true"
        end

        link :matches do |opts|
          request = Grape::Request.new(opts[:env])
          "#{request.base_url}/api/matches?channel_id=#{id}"
        end

        link :seasons do |opts|
          request = Grape::Request.new(opts[:env])
          "#{request.base_url}/api/seasons?channel_id=#{id}"
        end

        link :challenges do |opts|
          request = Grape::Request.new(opts[:env])
          "#{request.base_url}/api/challenges?channel_id=#{id}"
        end

        link :self do |opts|
          request = Grape::Request.new(opts[:env])
          "#{request.base_url}/api/channels/#{id}"
        end
      end
    end
  end
end
