module SlackGamebot
  module Api
    module Endpoints
      class TeamsEndpoint < Grape::API
        format :json
        helpers Api::Helpers::CursorHelpers
        helpers Api::Helpers::SortHelpers
        helpers Api::Helpers::PaginationParameters

        namespace :teams do
          desc 'Get a team.'
          params do
            requires :id, type: String, desc: 'Team ID.'
          end
          get ':id' do
            team = Team.find(params[:id]) || error!('Not Found', 404)
            error!('Not Found', 404) unless team.api?
            present team, with: SlackGamebot::Api::Presenters::TeamPresenter
          end

          desc 'Get all the teams.'
          params do
            optional :active, type: Boolean, desc: 'Return active teams only.'
            optional :game, type: String, desc: 'Return teams for a given game by name.'
            optional :game_id, type: String, desc: 'Return teams for a given game by ID.'
            mutually_exclusive :game, :game_id
            use :pagination
          end
          sort Team::SORT_ORDERS
          get do
            game = Game.find(params[:game_id]) if params.key?(:game_id)
            game ||= Game.where(name: params[:game]) if params.key?(:game)
            teams = game ? game.teams : Team.all
            teams = teams.api
            teams = teams.active if params[:active]
            teams = paginate_and_sort_by_cursor(teams, default_sort_order: '-_id')
            present teams, with: SlackGamebot::Api::Presenters::TeamsPresenter
          end

          desc 'Create a team using an OAuth token.'
          params do
            requires :code, type: String
            optional :game, type: String
            optional :game_id, type: String
            exactly_one_of :game, :game_id
          end
          post do
            game = Game.find(params[:game_id]) if params.key?(:game_id)
            game ||= Game.where(name: params[:game]).first if params.key?(:game)
            error!('Game Not Found', 404) unless game

            client = Slack::Web::Client.new

            rc = client.oauth_v2_access(
              client_id: game.client_id,
              client_secret: game.client_secret,
              code: params[:code]
            )

            access_token = rc.access_token
            token = rc.access_token
            user_id = rc.authed_user&.id
            bot_user_id = rc.bot_user_id
            team_id = rc.team&.id
            team_name = rc.team&.name
            oauth_scope = rc.scope
            team = Team.where(token: token).first
            team ||= Team.where(team_id: team_id, game: game, oauth_version: :v2).first
            team ||= Team.where(team_id: team_id, game: game).first

            if team
              error!('Invalid Game', 400) unless team.game == game

              team.ping_if_active!

              team.update_attributes!(
                oauth_version: :v2,
                token: token,
                activated_user_id: user_id,
                activated_user_access_token: access_token,
                bot_user_id: bot_user_id,
                oauth_scope: oauth_scope,
                dead_at: nil
              )

              raise "Team #{team.name} is already registered." if team.active?

              team.activate!(token)
            else
              team = Team.create!(
                game: game,
                aliases: game.aliases,
                token: token,
                team_id: team_id,
                name: team_name,
                activated_user_id: user_id,
                activated_user_access_token: access_token,
                bot_user_id: bot_user_id,
                oauth_scope: oauth_scope
              )
            end

            SlackRubyBotServer::Service.instance.create!(team)
            present team, with: SlackGamebot::Api::Presenters::TeamPresenter
          end
        end
      end
    end
  end
end
