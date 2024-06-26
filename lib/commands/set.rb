module SlackGamebot
  module Commands
    class Set < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::Admin

      class << self
        def set_nickname(channel, data, user, v)
          target_user = user
          slack_mention = v.split.first if v
          if v && User.slack_mention?(slack_mention)
            raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

            target_user = channel.find_or_create_by_mention!(slack_mention)
            v = v[slack_mention.length + 1..-1]
          end
          target_user.update_attributes!(nickname: v) unless v.nil?
          if target_user.nickname.blank?
            data.team.slack_client.say(channel: data.channel, text: "You don't have a nickname set, #{target_user.user_name}.", gif: 'anonymous')
            logger.info "SET: #{channel} - #{user.user_name}: nickname #{target_user == user ? '' : ' for ' + target_user.user_name}is not set"
          else
            data.team.slack_client.say(channel: data.channel, text: "Your nickname is #{v.nil? ? '' : 'now '}*#{target_user.nickname}*, #{target_user.slack_mention}.", gif: 'name')
            logger.info "SET: #{channel} - #{user.user_name} nickname #{target_user == user ? '' : ' for ' + target_user.user_name}is #{target_user.nickname}"
          end
        end

        def unset_nickname(channel, data, user, v)
          target_user = user
          slack_mention = v.split.first if v
          if slack_mention && User.slack_mention?(slack_mention)
            raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

            target_user = channel.find_or_create_by_mention!(slack_mention)
          end
          old_nickname = target_user.nickname
          target_user.update_attributes!(nickname: nil)
          data.team.slack_client.say(channel: data.channel, text: "You don't have a nickname set#{old_nickname.blank? ? '' : ' anymore'}, #{target_user.slack_mention}.", gif: 'anonymous')
          logger.info "UNSET: #{channel} - #{user.user_name}: nickname #{target_user == user ? '' : ' for ' + target_user.user_name} was #{old_nickname.blank? ? 'not ' : 'un'}set"
        end

        def set_gifs(channel, data, user, v)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?

          unless v.nil?
            channel.update_attributes!(gifs: v.to_b)
            data.team.slack_client.send_gifs = channel.gifs
          end
          data.team.slack_client.say(channel: data.channel, text: "GIFs for #{channel.slack_mention} are #{channel.gifs? ? 'on!' : 'off.'}", gif: 'fun')
          logger.info "SET: #{channel} - #{user.user_name} GIFs are #{channel.gifs? ? 'on' : 'off'}"
        end

        def unset_gifs(channel, data, user)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

          channel.update_attributes!(gifs: false)
          data.team.slack_client.send_gifs = channel.gifs
          data.team.slack_client.say(channel: data.channel, text: "GIFs for #{channel.slack_mention} are off.", gif: 'fun')
          logger.info "UNSET: #{channel} - #{user.user_name} GIFs are off"
        end

        def set_unbalanced(channel, data, user, v)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?

          channel.update_attributes!(unbalanced: v.to_b) unless v.nil?
          data.team.slack_client.say(channel: data.channel, text: "Unbalanced challenges for #{channel.slack_mention} are #{channel.unbalanced? ? 'on!' : 'off.'}", gif: 'balance')
          logger.info "SET: #{channel} - #{user.user_name} unbalanced challenges are #{channel.unbalanced? ? 'on' : 'off'}"
        end

        def unset_unbalanced(channel, data, user)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

          channel.update_attributes!(unbalanced: false)
          data.team.slack_client.say(channel: data.channel, text: "Unbalanced challenges for #{channel.slack_mention} are off.", gif: 'balance')
          logger.info "UNSET: #{channel} - #{user.user_name} unbalanced challenges are off"
        end

        def set_api(channel, data, user, v)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?

          channel.update_attributes!(api: v.to_b) unless v.nil?
          message = if channel.team.api && channel.api
                      "API for #{channel.slack_mention} is on!\nDM the bot for an API token to pass as an `X-Api-Token` header to #{channel.api_url}."
                    elsif !channel.team.api && channel.api
                      "API for team #{channel.team.team_id} is off. DM the bot to turn it on."
                    else
                      "API for #{channel.slack_mention} is off."
                    end
          data.team.slack_client.say(channel: data.channel, text: message, gif: 'programmer')
          logger.info "SET: #{channel} - #{user.user_name} API is #{channel.api? ? 'on' : 'off'}"
        end

        def unset_api(channel, data, user)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

          channel.update_attributes!(api: false)
          data.team.slack_client.say(channel: data.channel, text: "API for #{channel.slack_mention} is off.", gif: 'programmer')
          logger.info "UNSET: #{channel} - #{user.user_name} API is off"
        end

        def set_team_api(team, data, admin, v)
          raise SlackGamebot::Error, "You're not a team admin, sorry." unless v.nil? || admin.team_admin?

          team.update_attributes!(api: v.to_b) unless v.nil?
          message = if team.api && !team.api_token.blank?
                      "API for team #{team.team_id} is on, and the API token is set to `#{team.api_token}`.\nPass it in with an `X-Api-Token` header to #{team.api_url}."
                    elsif team.api
                      "API for team #{team.team_id} is on, set an API token with _set token xyz_."
                    else
                      "API for team #{team.team_id} is off."
                    end

          data.team.slack_client.say(channel: data.channel, text: message, gif: 'programmer')
          logger.info "SET: #{team} - #{admin.user_name} API is #{team.api? ? 'on' : 'off'}"
        end

        def unset_team_api(team, data, admin)
          raise SlackGamebot::Error, "You're not a team admin, sorry." unless admin.team_admin?

          team.update_attributes!(api: false)
          data.team.slack_client.say(channel: data.channel, text: "API for team #{team.team_id} is off.", gif: 'programmer')
          logger.info "UNSET: #{team} - #{admin.user_name} API is off"
        end

        def set_team_api_token(team, data, admin, v)
          raise SlackGamebot::Error, "You're not a team admin, sorry." unless admin.team_admin?

          team.update_attributes!(api_token: v.to_s) unless v.nil?
          message = if team.api && !team.api_token.blank?
                      "API for team #{team.team_id} is on, and the API token is `#{team.api_token}`.\nPass it in with an `X-Api-Token` header to #{team.api_url}."
                    elsif team.api && team.api_token.blank?
                      "API for team #{team.team_id} is on, set an API token with _set token xyz_."
                    elsif !team.api && !team.api_token.blank?
                      "API token for team #{team.team_id} is `#{team.api_token}`, but the API is off. Set it on with _set api on_."
                    else
                      "API token for team #{team.team_id} is not set, and the API is off. Set it on with _set api on_ and set a token with _set token xyz_."
                    end
          data.team.slack_client.say(channel: data.channel, text: message, gif: 'programmer')
          logger.info "SET: #{team} - #{admin.user_name} API token is #{team.api_token.blank? ? 'not set' : 'set'}"
        end

        def unset_team_api_token(team, data, admin)
          raise SlackGamebot::Error, "You're not a team admin, sorry." unless admin.team_admin?

          team.update_attributes!(api_token: nil)
          data.team.slack_client.say(channel: data.channel, text: "API token for team #{team.team_id} is not set.", gif: 'programmer')
          logger.info "UNSET: #{team} - #{admin.user_name} API token is not set"
        end

        def set_elo(channel, data, user, v)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?

          channel.update_attributes!(elo: parse_int(v)) unless v.nil?
          message = "Base elo for #{channel.slack_mention} is #{channel.elo}."
          data.team.slack_client.say(channel: data.channel, text: message, gif: 'score')
          logger.info "SET: #{channel} - #{user.user_name} ELO is #{channel.elo}"
        end

        def unset_elo(channel, data, user)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

          channel.update_attributes!(elo: 0)
          data.team.slack_client.say(channel: data.channel, text: "Base elo for #{channel.slack_mention} has been unset.", gif: 'score')
          logger.info "UNSET: #{channel} - #{user.user_name} ELO has been unset"
        end

        def set_leaderboard_max(channel, data, user, v)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?

          unless v.nil?
            v = parse_int_with_inifinity(v)
            channel.update_attributes!(leaderboard_max: v && v != 0 ? v : nil)
          end
          message = "Leaderboard max for #{channel.slack_mention} is #{channel.leaderboard_max || 'not set'}."
          data.team.slack_client.say(channel: data.channel, text: message, gif: 'count')
          logger.info "SET: #{channel} - #{user.user_name} LEADERBOARD MAX is #{channel.leaderboard_max}"
        end

        def unset_leaderboard_max(channel, data, user)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

          channel.update_attributes!(leaderboard_max: nil)
          data.team.slack_client.say(channel: data.channel, text: "Leaderboard max for #{channel.slack_mention} has been unset.", gif: 'score')
          logger.info "UNSET: #{channel} - #{user.user_name} LEADERBOARD MAX has been unset"
        end

        def set_aliases(channel, data, user, v)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?

          unless v.nil?
            channel.update_attributes!(aliases: v.split(/[\s,;]+/))
            channel.aliases = channel.aliases
          end
          if channel.aliases.length == 1
            data.team.slack_client.say(channel: data.channel, text: "Bot alias for #{channel.slack_mention} is #{channel.aliases_s}.", gif: 'name')
            logger.info "SET: #{channel} - #{user.user_name} Bot alias is #{channel.aliases.and}"
          elsif channel.aliases.any?
            data.team.slack_client.say(channel: data.channel, text: "Bot aliases for #{channel.slack_mention} are #{channel.aliases_s}.", gif: 'name')
            logger.info "SET: #{channel} - #{user.user_name} Bot aliases are #{channel.aliases.and}"
          else
            data.team.slack_client.say(channel: data.channel, text: "#{channel.slack_mention} does not have any bot aliases.", gif: 'name')
            logger.info "SET: #{channel} - #{user.user_name}, does not have any bot aliases"
          end
        end

        def unset_aliases(channel, data, user)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

          channel.update_attributes!(aliases: [])
          channel.aliases = []
          data.team.slack_client.say(channel: data.channel, text: "#{channel.slack_mention} no longer has bot aliases.", gif: 'name')
          logger.info "UNSET: #{channel} - #{user.user_name} no longer has bot aliases"
        end

        def parse_int_with_inifinity(v)
          v == 'infinity' ? nil : parse_int(v)
        end

        def parse_int(v)
          Integer(v)
        rescue StandardError
          raise SlackGamebot::Error, "Sorry, #{v} is not a valid number."
        end

        def set_channel(channel, data, user, k, v)
          case k
          when 'nickname'
            set_nickname channel, data, user, v
          when 'gifs'
            set_gifs channel, data, user, v
          when 'leaderboard'
            k, v = v.split(/\s+/, 2) if v
            case k
            when 'max'
              set_leaderboard_max channel, data, user, v
            else
              raise SlackGamebot::Error, "Invalid leaderboard setting #{k}, you can _set leaderboard max_."
            end
          when 'unbalanced'
            set_unbalanced channel, data, user, v
          when 'api'
            set_api channel, data, user, v
          when 'elo'
            set_elo channel, data, user, v
          when 'aliases'
            set_aliases channel, data, user, v
          else
            raise SlackGamebot::Error, "Invalid setting #{k}, you can _set gifs on|off_, _set unbalanced on|off_, _api on|off_, _leaderboard max_, _elo_, _nickname_ and _aliases_."
          end
        end

        def set_team(team, data, admin, k, v)
          case k
          when 'api'
            set_team_api team, data, admin, v
          when 'token'
            set_team_api_token team, data, admin, v
          else
            raise SlackGamebot::Error, "Invalid setting #{k}, you can _set api on|off_, and _set token xyz_."
          end
        end

        def unset_channel(channel, data, user, k, v)
          case k
          when 'nickname'
            unset_nickname channel, data, user, v
          when 'gifs'
            unset_gifs channel, data, user
          when 'leaderboard'
            case v
            when 'max'
              unset_leaderboard_max channel, data, user
            else
              raise SlackGamebot::Error, "Invalid leaderboard setting #{v}, you can _unset leaderboard max_."
            end
          when 'unbalanced'
            unset_unbalanced channel, data, user
          when 'api'
            unset_api channel, data, user
          when 'elo'
            unset_elo channel, data, user
          when 'aliases'
            unset_aliases channel, data, user
          else
            raise SlackGamebot::Error, "Invalid setting #{k}, you can _unset gifs_, _api_, _leaderboard max_, _elo_, _nickname_ and _aliases_."
          end
        end

        def unset_team(team, data, admin, k, _v)
          case k
          when 'api'
            unset_team_api team, data, admin
          when 'token'
            unset_team_api_token team, data, admin
          else
            raise SlackGamebot::Error, "Invalid setting #{k}, you can _unset api_ and _token_."
          end
        end
      end

      user_in_channel_or_dm_command 'unset' do |channel, user, data|
        if data.match['expression']
          k, v = data.match['expression'].split(/\s+/, 2)
          if channel
            unset_channel channel, data, user, k, v
          else
            unset_team data.team, data, user, k, v
          end
        else
          data.team.slack_client.say(channel: data.channel, text: 'Missing setting, eg. _unset gifs_.', gif: 'help')
          logger.info "UNSET: #{channel || 'DM'} - #{user.user_name}, failed, missing setting"
        end
      end

      user_in_channel_or_dm_command 'set' do |channel, user, data|
        if data.match['expression']
          k, v = data.match['expression'].split(/\s+/, 2)
          if channel
            set_channel channel, data, user, k, v
          else
            set_team data.team, data, user, k, v
          end
        else
          data.team.slack_client.say(channel: data.channel, text: 'Missing setting, eg. _set gifs off_.', gif: 'help')
          logger.info "SET: #{channel || 'DM'} - #{user.user_name}, failed, missing setting"
        end
      end
    end
  end
end
