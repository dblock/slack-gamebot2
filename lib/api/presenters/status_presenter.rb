module SlackGamebot
  module Api
    module Presenters
      module StatusPresenter
        include Roar::JSON::HAL
        include Roar::Hypermedia
        include Grape::Roar::Representer

        link :self do |opts|
          "#{base_url(opts)}/api/status"
        end

        property :ping
        property :teams_count
        property :channels_count
        property :active_teams_count
        property :api_teams_count
        property :api_channels_count
        property :users_count
        property :challenges_count
        property :matches_count
        property :seasons_count

        def teams_count
          Team.count
        end

        def channels_count
          Channel.count
        end

        def active_teams_count
          Team.active.count
        end

        def api_teams_count
          Team.api.count
        end

        def api_channels_count
          Channel.api.count
        end

        def users_count
          User.count
        end

        def challenges_count
          Challenge.count
        end

        def matches_count
          Match.count
        end

        def seasons_count
          Season.count
        end

        def ping
          team = Team.active.asc(:_id).first
          return unless team

          team.ping_if_active!
        end

        private

        def base_url(opts)
          request = Grape::Request.new(opts[:env])
          request.base_url
        end
      end
    end
  end
end
