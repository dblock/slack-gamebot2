# frozen_string_literal: true

module SlackGamebot
  module Commands
    module SetChannel
      def set_channel_info(channel, data, user)
        channel.slack_client.say(
          channel: data.channel,
          text: [
            "API for channel #{channel.slack_mention} is #{channel.api_s}, and the team API token is #{channel.team.api_token.blank? ? 'not set' : 'set'}.",
            channel.is_group ? nil : "Bot aliases are #{channel.aliases_s}.",
            "GIFs are #{channel.gifs_s}.",
            "Elo is #{channel.elo}.",
            "Leaderboard max is #{channel.leaderboard_max_s}.",
            "Unbalanced challenges are #{channel.unbalanced_s} by default."
          ].compact.join("\n"),
          gif: 'settings'
        )
        logger.info "SET: #{channel} - #{user.user_name}: show current values"
      end

      def set_nickname(channel, data, user, v)
        target_user = user
        slack_mention = v.split.first if v
        if v && User.slack_mention?(slack_mention)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

          target_user = channel.find_or_create_by_mention!(slack_mention)
          v = v[slack_mention.length + 1..]
        end
        target_user.update_attributes!(nickname: v) unless v.nil?
        if target_user.nickname.blank?
          channel.slack_client.say(channel: data.channel, text: "You don't have a nickname set, #{target_user.user_name}.", gif: 'anonymous')
          logger.info "SET: #{channel} - #{user.user_name}: nickname #{target_user == user ? '' : " for #{target_user.user_name}"}is not set"
        else
          channel.slack_client.say(channel: data.channel, text: "Your nickname is #{v.nil? ? '' : 'now '}_#{target_user.nickname}_, #{target_user.slack_mention}.", gif: 'name')
          logger.info "SET: #{channel} - #{user.user_name}: nickname #{target_user == user ? '' : " for #{target_user.user_name}"}is #{target_user.nickname}"
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
        channel.slack_client.say(channel: data.channel, text: "You don't have a nickname set#{old_nickname.blank? ? '' : ' anymore'}, #{target_user.slack_mention}.", gif: 'anonymous')
        logger.info "UNSET: #{channel} - #{user.user_name}: nickname #{target_user == user ? '' : " for #{target_user.user_name}"} was #{old_nickname.blank? ? 'not ' : 'un'}set"
      end

      def set_gifs(channel, data, user, v)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?

        unless v.nil?
          channel.update_attributes!(gifs: v.to_b)
          channel.slack_client.gifs = channel.gifs
        end
        channel.slack_client.say(channel: data.channel, text: "GIFs for #{channel.slack_mention} are #{channel.gifs? ? 'on!' : 'off.'}", gif: 'fun')
        logger.info "SET: #{channel} - #{user.user_name}: GIFs are #{channel.gifs? ? 'on' : 'off'}"
      end

      def unset_gifs(channel, data, user)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

        channel.update_attributes!(gifs: false)
        channel.slack_client.gifs = channel.gifs
        channel.slack_client.say(channel: data.channel, text: "GIFs for #{channel.slack_mention} are off.", gif: 'fun')
        logger.info "UNSET: #{channel} - #{user.user_name}: GIFs are off"
      end

      def set_unbalanced(channel, data, user, v)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?

        channel.update_attributes!(unbalanced: v.to_b) unless v.nil?
        channel.slack_client.say(channel: data.channel, text: "Unbalanced challenges for #{channel.slack_mention} are #{channel.unbalanced? ? 'on!' : 'off.'}", gif: 'balance')
        logger.info "SET: #{channel} - #{user.user_name}: unbalanced challenges are #{channel.unbalanced? ? 'on' : 'off'}"
      end

      def unset_unbalanced(channel, data, user)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

        channel.update_attributes!(unbalanced: false)
        channel.slack_client.say(channel: data.channel, text: "Unbalanced challenges for #{channel.slack_mention} are off.", gif: 'balance')
        logger.info "UNSET: #{channel} - #{user.user_name}: unbalanced challenges are off"
      end

      def set_api(channel, data, user, v)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?

        channel.update_attributes!(api: v.to_b) unless v.nil?
        message = if channel.team.api && channel.api
                    "API for #{channel.slack_mention} is on!\nDM the bot _set token_ to get or set an API token to pass as an `X-Access-Token` header to #{channel.api_url}."
                  elsif !channel.team.api && channel.api
                    "API for team #{channel.team.team_id} is off. DM the bot to turn it on."
                  else
                    "API for #{channel.slack_mention} is off."
                  end
        channel.slack_client.say(channel: data.channel, text: message, gif: 'programmer')
        logger.info "SET: #{channel} - #{user.user_name}: API is #{channel.api? ? 'on' : 'off'}"
      end

      def unset_api(channel, data, user)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

        channel.update_attributes!(api: false)
        channel.slack_client.say(channel: data.channel, text: "API for #{channel.slack_mention} is off.", gif: 'programmer')
        logger.info "UNSET: #{channel} - #{user.user_name}: API is off"
      end

      def set_elo(channel, data, user, v)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?

        channel.update_attributes!(elo: parse_int(v)) unless v.nil?
        message = "Base elo for #{channel.slack_mention} is #{channel.elo}."
        channel.slack_client.say(channel: data.channel, text: message, gif: 'score')
        logger.info "SET: #{channel} - #{user.user_name}: ELO is #{channel.elo}"
      end

      def unset_elo(channel, data, user)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

        channel.update_attributes!(elo: 0)
        channel.slack_client.say(channel: data.channel, text: "Base elo for #{channel.slack_mention} has been unset.", gif: 'score')
        logger.info "UNSET: #{channel} - #{user.user_name}: ELO has been unset"
      end

      def set_leaderboard_max(channel, data, user, v)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?

        unless v.nil?
          v = parse_int_with_inifinity(v)
          channel.update_attributes!(leaderboard_max: v && v != 0 ? v : nil)
        end
        message = "Leaderboard max for #{channel.slack_mention} is #{channel.leaderboard_max || 'not set'}."
        channel.slack_client.say(channel: data.channel, text: message, gif: 'count')
        logger.info "SET: #{channel} - #{user.user_name}: leaderboard max is #{channel.leaderboard_max}"
      end

      def unset_leaderboard_max(channel, data, user)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

        channel.update_attributes!(leaderboard_max: nil)
        channel.slack_client.say(channel: data.channel, text: "Leaderboard max for #{channel.slack_mention} has been unset.", gif: 'score')
        logger.info "UNSET: #{channel} - #{user.user_name}: leaderboard max has been unset"
      end

      def set_aliases(channel, data, user, v)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?
        raise SlackGamebot::Error, 'Bot aliases are not supported in private channels, sorry.' if channel.is_group?

        unless v.nil?
          channel.update_attributes!(aliases: v.split(/[\s,;]+/))
          channel.aliases = channel.aliases
        end
        if channel.aliases.length == 1
          channel.slack_client.say(channel: data.channel, text: "Bot alias for #{channel.slack_mention} is #{channel.aliases_s}.", gif: 'name')
          logger.info "SET: #{channel} - #{user.user_name}: Bot alias is #{channel.aliases.and}"
        elsif channel.aliases.any?
          channel.slack_client.say(channel: data.channel, text: "Bot aliases for #{channel.slack_mention} are #{channel.aliases_s}.", gif: 'name')
          logger.info "SET: #{channel} - #{user.user_name}: Bot aliases are #{channel.aliases.and}"
        else
          channel.slack_client.say(channel: data.channel, text: "#{channel.slack_mention} does not have any bot aliases.", gif: 'name')
          logger.info "SET: #{channel} - #{user.user_name}: does not have any bot aliases"
        end
      end

      def unset_aliases(channel, data, user)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?
        raise SlackGamebot::Error, 'Bot aliases are not supported in private channels, sorry.' if channel.is_group?

        channel.update_attributes!(aliases: [])
        channel.aliases = []
        channel.slack_client.say(channel: data.channel, text: "#{channel.slack_mention} no longer has bot aliases.", gif: 'name')
        logger.info "UNSET: #{channel} - #{user.user_name}: no longer has bot aliases"
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
        when nil
          set_channel_info channel, data, user
        else
          raise SlackGamebot::Error, "Invalid setting #{k}, you can _set gifs on|off_, _set unbalanced on|off_, _api on|off_, _leaderboard max_, _elo_, _nickname_ and _aliases_."
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
        when nil
          raise SlackGamebot::Error, 'Missing setting, you can _unset gifs_, _api_, _leaderboard max_, _elo_, _nickname_ and _aliases_.'
        else
          raise SlackGamebot::Error, "Invalid setting #{k}, you can _unset gifs_, _api_, _leaderboard max_, _elo_, _nickname_ and _aliases_."
        end
      end
    end
  end
end
