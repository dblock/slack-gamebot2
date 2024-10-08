# frozen_string_literal: true

module SlackGamebot
  module Api
    module Presenters
      module UserPresenter
        include Roar::JSON::HAL
        include Roar::Hypermedia
        include Grape::Roar::Representer

        property :id, type: String, desc: 'User ID.'
        property :user_name, type: String, desc: 'User name.'
        property :nickname, type: String, desc: 'Optional nickname.'
        property :wins, type: Integer, desc: 'Number of wins.'
        property :losses, type: Integer, desc: 'Number of losses.'
        property :elo, type: Integer, desc: 'Elo.'
        property :elo_history, type: [Integer], desc: 'Elo history.'
        property :rank, type: Integer, desc: 'Rank.'
        property :winning_streak, type: Integer, desc: 'Longest winning streak this season.'
        property :losing_streak, type: Integer, desc: 'Longest losing streak this season.'
        property :registered, type: ::Grape::API::Boolean, desc: 'User registered or unregistered.'
        property :created_at, as: :registered_at, type: DateTime, desc: 'Date/time when the user has registered.'
        property :captain, type: ::Grape::API::Boolean, desc: 'Team captain.'

        link :channel do |opts|
          request = Grape::Request.new(opts[:env])
          "#{request.base_url}/api/channels/#{represented.channel.id}" if represented.channel
        end

        link :self do |opts|
          request = Grape::Request.new(opts[:env])
          "#{request.base_url}/api/users/#{id}"
        end
      end
    end
  end
end
