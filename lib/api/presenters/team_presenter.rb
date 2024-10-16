# frozen_string_literal: true

module SlackGamebot
  module Api
    module Presenters
      module TeamPresenter
        include Roar::JSON::HAL
        include Roar::Hypermedia
        include Grape::Roar::Representer

        property :id, type: String, desc: 'Team ID.'
        property :team_id, type: String, desc: 'Slack team ID.'
        property :name, type: String, desc: 'Team name.'
        property :domain, type: String, desc: 'Team domain.'
        property :active, type: ::Grape::API::Boolean, desc: 'Team is active.'
        property :subscribed, type: ::Grape::API::Boolean, desc: 'Team is a subscriber.'
        property :created_at, type: DateTime, desc: 'Date/time when the team was created.'
        property :updated_at, type: DateTime, desc: 'Date/time when the team was accepted, declined or canceled.'

        link :channels do |opts|
          request = Grape::Request.new(opts[:env])
          "#{request.base_url}/api/channels?team_id=#{represented.id}"
        end

        link :self do |opts|
          request = Grape::Request.new(opts[:env])
          "#{request.base_url}/api/teams/#{id}"
        end
      end
    end
  end
end
