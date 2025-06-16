# frozen_string_literal: true

module SlackGamebot
  module Api
    module Presenters
      module EloChangePresenter
        include Roar::JSON::HAL
        include Roar::Hypermedia
        include Grape::Roar::Representer

        property :elo_i, type: Integer, desc: 'Previous elo.', as: :elo
        property :delta_i, type: Integer, desc: 'Elo change.', as: :delta
        property :new_channel_elo_i, type: Integer, desc: 'Adjusted elo.', as: :new_elo

        def elo_i
          channel_elo.to_i
        end

        def delta_i
          delta.to_i
        end

        def new_channel_elo_i
          new_channel_elo.to_i
        end

        link :user do |opts|
          request = Grape::Request.new(opts[:env])
          "#{request.base_url}/api/users/#{represented.user.id}" if represented.user
        end
      end
    end
  end
end
