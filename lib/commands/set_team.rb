# frozen_string_literal: true

module SlackGamebot
  module Commands
    module SetTeam
      def set_team_info(team, data, admin)
        team.slack_client.say(
          channel: data.channel,
          text: [
            "API for team #{team.team_id} is #{team.api_s}, and the API token is #{team.api_token.blank? ? 'not set' : 'set'}.",
            "Default bot aliases are #{team.aliases_s}.",
            "GIFs are #{team.gifs_s} by default.",
            "Default elo is #{team.elo}.",
            "Default leaderboard max is #{team.leaderboard_max_s}.",
            "Unbalanced challenges are #{team.unbalanced_s} by default."
          ].join("\n"),
          gif: 'settings'
        )
        logger.info "SET: #{team} - #{admin.user_name}: show current values"
      end

      def set_team_gifs(team, data, admin, v)
        raise SlackGamebot::Error, "You're not a team admin, sorry." unless v.nil? || admin.team_admin?

        team.update_attributes!(gifs: v.to_b) unless v.nil?
        team.slack_client.say(channel: data.channel, text: "GIFs are #{team.gifs? ? 'on by default!' : 'off by default.'}", gif: 'fun')
        logger.info "SET: #{team} - #{admin.user_name}: GIFs are #{team.gifs? ? 'on by default' : 'off by default'}"
      end

      def unset_team_gifs(team, data, admin)
        raise SlackGamebot::Error, "You're not a team admin, sorry." unless admin.team_admin?

        team.update_attributes!(gifs: false)
        team.slack_client.gifs = team.gifs
        team.slack_client.say(channel: data.channel, text: 'GIFs are off by default.', gif: 'fun')
        logger.info "UNSET: #{team} - #{admin.user_name}: GIFs are off by default"
      end

      def set_team_unbalanced(team, data, admin, v)
        raise SlackGamebot::Error, "You're not a team admin, sorry." unless v.nil? || admin.team_admin?

        team.update_attributes!(unbalanced: v.to_b) unless v.nil?
        team.slack_client.say(channel: data.channel, text: "Unbalanced challenges are #{team.unbalanced? ? 'on by default!' : 'off by default.'}", gif: 'balance')
        logger.info "SET: #{team} - #{admin.user_name}: unbalanced challenges are #{team.unbalanced? ? 'on by default' : 'off by default'}"
      end

      def unset_team_unbalanced(team, data, admin)
        raise SlackGamebot::Error, "You're not a team admin, sorry." unless admin.team_admin?

        team.update_attributes!(unbalanced: false)
        team.slack_client.say(channel: data.channel, text: 'Unbalanced challenges are off by default.', gif: 'balance')
        logger.info "UNSET: #{team} - #{admin.user_name}: unbalanced challenges are off by default"
      end

      def set_team_api(team, data, admin, v)
        raise SlackGamebot::Error, "You're not a team admin, sorry." unless v.nil? || admin.team_admin?

        team.update_attributes!(api: v.to_b) unless v.nil?
        message = if team.api && !team.api_token.blank?
                    "API for team #{team.team_id} is #{v.nil? ? '' : 'now '}on, and the API token is set to `#{team.api_token}`.\nPass it in with an `X-Access-Token` header to #{team.api_url}."
                  elsif team.api
                    "API for team #{team.team_id} is #{v.nil? ? '' : 'now '}on, set an API token with _set token xyz_."
                  else
                    "API for team #{team.team_id} is #{v.nil? ? '' : 'now '}off."
                  end

        team.slack_client.say(channel: data.channel, text: message, gif: 'programmer')
        logger.info "SET: #{team} - #{admin.user_name}: API is #{team.api? ? 'on' : 'off'}"
      end

      def unset_team_api(team, data, admin)
        raise SlackGamebot::Error, "You're not a team admin, sorry." unless admin.team_admin?

        team.update_attributes!(api: false)
        team.slack_client.say(channel: data.channel, text: "API for team #{team.team_id} is now off.", gif: 'programmer')
        logger.info "UNSET: #{team} - #{admin.user_name}: API is off"
      end

      def set_team_api_token(team, data, admin, v)
        raise SlackGamebot::Error, "You're not a team admin, sorry." unless admin.team_admin?

        team.update_attributes!(api_token: v.to_s) unless v.nil?
        message = if team.api && !team.api_token.blank?
                    "API for team #{team.team_id} is on, and the API token is #{v.nil? ? '' : 'now '}`#{team.api_token}`.\nPass it in with an `X-Access-Token` header to #{team.api_url}."
                  elsif team.api && team.api_token.blank?
                    "API for team #{team.team_id} is on, set an API token with _set token xyz_."
                  elsif !team.api && !team.api_token.blank?
                    "API token for team #{team.team_id} is #{v.nil? ? '' : 'now '}`#{team.api_token}`, but the API is off. Set it on with _set api on_."
                  else
                    "API token for team #{team.team_id} is not set, and the API is off. Set it on with _set api on_ and set a token with _set token xyz_."
                  end
        team.slack_client.say(channel: data.channel, text: message, gif: 'programmer')
        logger.info "SET: #{team} - #{admin.user_name}: API token is #{team.api_token.blank? ? 'not set' : 'set'}"
      end

      def unset_team_api_token(team, data, admin)
        raise SlackGamebot::Error, "You're not a team admin, sorry." unless admin.team_admin?

        team.update_attributes!(api_token: nil)
        team.slack_client.say(channel: data.channel, text: "API token for team #{team.team_id} has been unset.", gif: 'programmer')
        logger.info "UNSET: #{team} - #{admin.user_name}: API token is not set"
      end

      def set_team_elo(team, data, admin, v)
        raise SlackGamebot::Error, "You're not a team admin, sorry." unless v.nil? || admin.team_admin?

        team.update_attributes!(elo: parse_int(v)) unless v.nil?
        message = "Default base elo is #{v.nil? ? '' : 'now '}#{team.elo}."
        team.slack_client.say(channel: data.channel, text: message, gif: 'score')
        logger.info "SET: #{team} - #{admin.user_name}: default elo is #{team.elo}"
      end

      def unset_team_elo(team, data, admin)
        raise SlackGamebot::Error, "You're not a team admin, sorry." unless admin.team_admin?

        team.update_attributes!(elo: 0)
        team.slack_client.say(channel: data.channel, text: 'Default base elo has been unset.', gif: 'score')
        logger.info "UNSET: #{team} - #{admin.user_name}: default base elo has been unset"
      end

      def set_team_leaderboard_max(team, data, admin, v)
        raise SlackGamebot::Error, "You're not a team admin, sorry." unless v.nil? || admin.team_admin?

        unless v.nil?
          v = parse_int_with_inifinity(v)
          team.update_attributes!(leaderboard_max: v && v != 0 ? v : nil)
        end
        message = "Default leaderboard max is #{v.nil? ? '' : 'now '}#{team.leaderboard_max || 'not set'}."
        team.slack_client.say(channel: data.channel, text: message, gif: 'count')
        logger.info "SET: #{team} - #{admin.user_name}: default leaderboard max is #{team.leaderboard_max}"
      end

      def unset_team_leaderboard_max(team, data, admin)
        raise SlackGamebot::Error, "You're not a team admin, sorry." unless admin.team_admin?

        team.update_attributes!(leaderboard_max: nil)
        team.slack_client.say(channel: data.channel, text: 'Default leaderboard max has been unset.', gif: 'score')
        logger.info "UNSET: #{team} - #{admin.user_name}: default leaderboard max has been unset"
      end

      def set_team_aliases(team, data, admin, v)
        raise SlackGamebot::Error, "You're not a team admin, sorry." unless v.nil? || admin.team_admin?

        team.update_attributes!(aliases: v.split(/[\s,;]+/)) unless v.nil?
        if team.aliases.length == 1
          team.slack_client.say(channel: data.channel, text: "Default bot alias is #{v.nil? ? '' : 'now '}#{team.aliases_s}.", gif: 'name')
          logger.info "SET: #{team} - #{admin.user_name}: Default bot alias is #{team.aliases.and}"
        elsif team.aliases.any?
          team.slack_client.say(channel: data.channel, text: "Default bot aliases are #{v.nil? ? '' : 'now '}#{team.aliases_s}.", gif: 'name')
          logger.info "SET: #{team} - #{admin.user_name}: Default bot aliases are #{team.aliases.and}"
        else
          team.slack_client.say(channel: data.channel, text: 'No default bot aliases set.', gif: 'name')
          logger.info "SET: #{team} - #{admin.user_name}: no default bot aliases set"
        end
      end

      def unset_team_aliases(team, data, admin)
        raise SlackGamebot::Error, "You're not a team admin, sorry." unless admin.team_admin?

        team.update_attributes!(aliases: [])
        team.aliases = []
        team.slack_client.say(channel: data.channel, text: 'Default bot aliases unset.', gif: 'name')
        logger.info "UNSET: #{team} - #{admin.user_name}: default bot aliases unset"
      end

      def set_team(team, data, admin, k, v)
        case k
        when 'token'
          set_team_api_token team, data, admin, v
        when 'gifs'
          set_team_gifs team, data, admin, v
        when 'leaderboard'
          k, v = v.split(/\s+/, 2) if v
          case k
          when 'max'
            set_team_leaderboard_max team, data, admin, v
          else
            raise SlackGamebot::Error, "Invalid leaderboard setting #{k}, you can _set leaderboard max_."
          end
        when 'unbalanced'
          set_team_unbalanced team, data, admin, v
        when 'api'
          set_team_api team, data, admin, v
        when 'elo'
          set_team_elo team, data, admin, v
        when 'aliases'
          set_team_aliases team, data, admin, v
        when nil
          set_team_info team, data, admin
        else
          raise SlackGamebot::Error, "Invalid setting #{k}, you can _set gifs on|off_, _set unbalanced on|off_, _api on|off_, _set token xyz_, _leaderboard max_, _elo_ and _aliases_."
        end
      end

      def unset_team(team, data, admin, k, v)
        case k
        when 'token'
          unset_team_api_token team, data, admin
        when 'gifs'
          unset_team_gifs team, data, admin
        when 'leaderboard'
          case v
          when 'max'
            unset_team_leaderboard_max team, data, admin
          else
            raise SlackGamebot::Error, "Invalid leaderboard setting #{v}, you can _unset leaderboard max_."
          end
        when 'unbalanced'
          unset_team_unbalanced team, data, admin
        when 'api'
          unset_team_api team, data, admin
        when 'elo'
          unset_team_elo team, data, admin
        when 'aliases'
          unset_team_aliases team, data, admin
        when nil
          raise SlackGamebot::Error, 'Missing setting, you can _unset gifs_, _unbalanced_, _api_, _token_, _leaderboard max_, _elo_ and _aliases_.'
        else
          raise SlackGamebot::Error, "Invalid setting #{k}, you can _unset gifs_, _unbalanced_, _api_, _token_, _leaderboard max_, _elo_ and _aliases_."
        end
      end
    end
  end
end
