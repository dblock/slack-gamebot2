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
            channel.expire_message,
            channel.remind_message,
            "GIFs are #{channel.gifs_s}.",
            "Elo is #{channel.elo}.",
            "Elo algorithm is #{channel.elo_algorithm_s}.",
            "Leaderboard max is #{channel.leaderboard_max_s}.",
            "Max challenges number is #{channel.max_challenges_s}.",
            "Max challenges per day is #{channel.max_challenges_per_day_s}.",
            "Max challenges per user is #{channel.max_challenges_per_user_s}.",
            "Timezone is #{channel.timezone_s}.",
            "Unbalanced challenges are #{channel.unbalanced_s} by default.",
            "Won command is #{channel.won_s}."
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
          logger.info "SET: #{channel} - #{user.user_name}: nickname #{" for #{target_user.user_name}" unless target_user == user}is not set"
        else
          channel.slack_client.say(channel: data.channel, text: "Your nickname is #{'now ' unless v.nil?}_#{target_user.nickname}_, #{target_user.slack_mention}.", gif: 'name')
          logger.info "SET: #{channel} - #{user.user_name}: nickname #{" for #{target_user.user_name}" unless target_user == user}is #{target_user.nickname}"
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
        channel.slack_client.say(channel: data.channel, text: "You don't have a nickname set#{' anymore' unless old_nickname.blank?}, #{target_user.slack_mention}.", gif: 'anonymous')
        logger.info "UNSET: #{channel} - #{user.user_name}: nickname #{" for #{target_user.user_name}" unless target_user == user} was #{old_nickname.blank? ? 'not ' : 'un'}set"
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

      def set_details(channel, data, user, v)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?

        if v&.downcase == 'none'
          channel.update_attributes!(details: [])
        else
          channel.update_attributes!(details: v.split(/[\s,;]+/).map { |detail| Details.parse_s(detail) }) unless v.nil?
        end
        channel.slack_client.say(channel: data.channel, text: "Match details for #{channel.slack_mention} are #{channel.details_s}.", gif: 'details')
        logger.info "SET: #{channel} - #{user.user_name}: match details are #{channel.details_s}"
      end

      def unset_details(channel, data, user)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

        channel.update_attributes!(details: [])
        channel.slack_client.say(channel: data.channel, text: "Match details for #{channel.slack_mention} are not shown.", gif: 'details')
        logger.info "UNSET: #{channel} - #{user.user_name}: match details are not shown"
      end

      def set_won(channel, data, user, v)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?

        channel.update_attributes!(won: v.to_b) unless v.nil?
        channel.slack_client.say(channel: data.channel, text: "Won command for #{channel.slack_mention} is #{channel.won? ? 'on!' : 'off.'}", gif: 'winner')
        logger.info "SET: #{channel} - #{user.user_name}: won command is #{channel.won? ? 'on' : 'off'}"
      end

      def unset_won(channel, data, user)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

        channel.update_attributes!(won: false)
        channel.slack_client.say(channel: data.channel, text: "Won command for #{channel.slack_mention} is off.", gif: 'winner')
        logger.info "UNSET: #{channel} - #{user.user_name}: won command is off"
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

        if v
          k, v = v.split(/\s+/, 2)
          case k
          when 'algorithm'
            set_elo_algorithm channel, data, user, v
          when 'k'
            set_elo_k channel, data, user, v
          when 'decay'
            set_elo_decay channel, data, user, v
          when 'glicko2'
            sub, val = v&.split(/\s+/, 2)
            set_elo_glicko2 channel, data, user, sub, val
          else
            channel.update_attributes!(elo: parse_int(k))
            message = "Base elo for #{channel.slack_mention} is #{channel.elo}."
            channel.slack_client.say(channel: data.channel, text: message, gif: 'score')
            logger.info "SET: #{channel} - #{user.user_name}: ELO is #{channel.elo}"
          end
        else
          message = "Base elo for #{channel.slack_mention} is #{channel.elo}."
          channel.slack_client.say(channel: data.channel, text: message, gif: 'score')
          logger.info "SET: #{channel} - #{user.user_name}: ELO is #{channel.elo}"
        end
      end

      def set_elo_algorithm(channel, data, user, v)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?

        if v
          raise SlackGamebot::Error, "Invalid elo algorithm #{v}, valid options are: #{Elo::ALGORITHMS.join(', ')}." unless Elo::ALGORITHMS.include?(v.downcase)
          raise SlackGamebot::Error, 'Elo algorithm can only be changed at the start of a new season.' if channel.matches.current.any?

          channel.update_attributes!(elo_algorithm: v.downcase)
        end
        channel.slack_client.say(channel: data.channel, text: "Elo algorithm for #{channel.slack_mention} is #{channel.elo_algorithm_s}.", gif: 'score')
        logger.info "SET: #{channel} - #{user.user_name}: elo algorithm is #{channel.elo_algorithm_s}"
      end

      def set_elo_k(channel, data, user, v)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?
        raise SlackGamebot::Error, 'K can only be set when the elo algorithm is standard.' unless channel.elo_algorithm == 'standard'

        channel.update_attributes!(elo_k: parse_int(v)) if v
        channel.slack_client.say(channel: data.channel, text: "Elo K for #{channel.slack_mention} is #{channel.elo_k}.", gif: 'score')
        logger.info "SET: #{channel} - #{user.user_name}: elo K is #{channel.elo_k}"
      end

      def set_elo_decay(channel, data, user, v)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?
        raise SlackGamebot::Error, 'Decay can only be set when the elo algorithm is adaptive.' unless channel.elo_algorithm == 'adaptive'

        if v
          decay = Float(v)
          raise SlackGamebot::Error, 'Elo decay must be between 0 and 1.' unless decay.positive? && decay < 1

          channel.update_attributes!(elo_decay: decay)
        end
        channel.slack_client.say(channel: data.channel, text: "Elo decay for #{channel.slack_mention} is #{channel.elo_decay}.", gif: 'score')
        logger.info "SET: #{channel} - #{user.user_name}: elo decay is #{channel.elo_decay}"
      rescue ArgumentError
        raise SlackGamebot::Error, "Sorry, #{v} is not a valid number."
      end

      def set_elo_glicko2(channel, data, user, sub_cmd, v)
        case sub_cmd&.downcase
        when 'tau' then set_elo_glicko2_tau(channel, data, user, v)
        else raise SlackGamebot::Error, "Unknown glicko2 parameter #{sub_cmd}, valid options are: tau."
        end
      end

      def set_elo_glicko2_tau(channel, data, user, v)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?
        raise SlackGamebot::Error, 'Glicko2 τ can only be set when the elo algorithm is glicko2.' unless channel.elo_algorithm == 'glicko2'

        if v
          tau = Float(v)
          raise SlackGamebot::Error, 'Glicko2 τ must be positive.' unless tau.positive?

          channel.update_attributes!(elo_glicko2_tau: tau)
        end
        channel.slack_client.say(channel: data.channel, text: "Glicko2 τ for #{channel.slack_mention} is #{channel.elo_glicko2_tau}.", gif: 'score')
        logger.info "SET: #{channel} - #{user.user_name}: elo glicko2 tau is #{channel.elo_glicko2_tau}"
      rescue ArgumentError
        raise SlackGamebot::Error, "Sorry, #{v} is not a valid number."
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
          v = parse_int_or_none(v)
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

      def set_max_challenges(channel, data, user, v)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

        if v&.match?(/\Aper\s+day\b/i)
          set_max_challenges_per_day channel, data, user, v.sub(/\Aper\s+day\s*/i, '')
        elsif v&.match?(/\Aper\s+user\b/i)
          set_max_challenges_per_user channel, data, user, v.sub(/\Aper\s+user\s*/i, '')
        elsif v.nil? || v.strip == 'none'
          channel.update_attributes!(max_challenges: nil)
          channel.slack_client.say(channel: data.channel, text: 'Max challenges number removed.', gif: 'count')
          logger.info "SET: #{channel} - #{user.user_name}: max_challenges removed"
        else
          n = parse_int_or_none(v)
          channel.update_attributes!(max_challenges: n&.positive? ? n : nil)
          channel.slack_client.say(channel: data.channel, text: "Max challenges number is #{channel.max_challenges_s}.", gif: 'count')
          logger.info "SET: #{channel} - #{user.user_name}: max_challenges=#{channel.max_challenges_s}"
        end
      end

      def set_max_challenges_per_day(channel, data, user, v)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

        if v.nil? || v.strip.empty? || v.strip == 'none'
          channel.update_attributes!(max_challenges_per_day: nil)
          channel.slack_client.say(channel: data.channel, text: 'Max challenges per day removed.', gif: 'count')
          logger.info "SET: #{channel} - #{user.user_name}: max_challenges_per_day removed"
        else
          n = parse_int_or_none(v)
          channel.update_attributes!(max_challenges_per_day: n&.positive? ? n : nil)
          channel.slack_client.say(channel: data.channel, text: "Max challenges per day is #{channel.max_challenges_per_day_s}.", gif: 'count')
          logger.info "SET: #{channel} - #{user.user_name}: max_challenges_per_day=#{channel.max_challenges_per_day_s}"
        end
      end

      def set_max_challenges_per_user(channel, data, user, v)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

        if v.nil? || v.strip.empty? || v.strip == 'none'
          channel.update_attributes!(max_challenges_per_user: nil)
          channel.slack_client.say(channel: data.channel, text: 'Max challenges per user removed.', gif: 'count')
          logger.info "SET: #{channel} - #{user.user_name}: max_challenges_per_user removed"
        else
          n = parse_int_or_none(v)
          channel.update_attributes!(max_challenges_per_user: n&.positive? ? n : nil)
          channel.slack_client.say(channel: data.channel, text: "Max challenges per user is #{channel.max_challenges_per_user_s}.", gif: 'count')
          logger.info "SET: #{channel} - #{user.user_name}: max_challenges_per_user=#{channel.max_challenges_per_user_s}"
        end
      end

      def unset_max_challenges(channel, data, user, v = nil)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

        if v&.match?(/\Aper\s+day\z/i)
          channel.update_attributes!(max_challenges_per_day: nil)
          channel.slack_client.say(channel: data.channel, text: 'Max challenges per day removed.', gif: 'count')
          logger.info "UNSET: #{channel} - #{user.user_name}: max_challenges_per_day removed"
        elsif v&.match?(/\Aper\s+user\z/i)
          channel.update_attributes!(max_challenges_per_user: nil)
          channel.slack_client.say(channel: data.channel, text: 'Max challenges per user removed.', gif: 'count')
          logger.info "UNSET: #{channel} - #{user.user_name}: max_challenges_per_user removed"
        else
          channel.update_attributes!(max_challenges: nil)
          channel.slack_client.say(channel: data.channel, text: 'Max challenges number removed.', gif: 'count')
          logger.info "UNSET: #{channel} - #{user.user_name}: max_challenges removed"
        end
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

      def set_expire(channel, data, user, v)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?

        unless v.nil?
          expire = parse_duration(v)
          raise SlackGamebot::Error, "Expire must be after remind (currently #{channel.remind_s})." if expire && channel.remind && expire <= channel.remind

          channel.update_attributes!(expire: expire)
        end
        channel.slack_client.say(channel: data.channel, text: channel.expire_message, gif: 'timer')
        logger.info "SET: #{channel} - #{user.user_name}: #{channel.expire_message}"
      end

      def unset_expire(channel, data, user)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

        channel.update_attributes!(expire: nil)
        channel.slack_client.say(channel: data.channel, text: channel.expire_message, gif: 'timer')
        logger.info "UNSET: #{channel} - #{user.user_name}: #{channel.expire_message}"
      end

      def set_remind(channel, data, user, v)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?

        unless v.nil?
          remind = parse_duration(v)
          raise SlackGamebot::Error, "Remind must be before expire (currently #{channel.expire_s})." if remind && channel.expire && remind >= channel.expire

          channel.update_attributes!(remind: remind)
        end
        channel.slack_client.say(channel: data.channel, text: channel.remind_message, gif: 'timer')
        logger.info "SET: #{channel} - #{user.user_name}: #{channel.remind_message}"
      end

      def unset_remind(channel, data, user)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

        channel.update_attributes!(remind: nil)
        channel.slack_client.say(channel: data.channel, text: channel.remind_message, gif: 'timer')
        logger.info "UNSET: #{channel} - #{user.user_name}: #{channel.remind_message}"
      end

      def set_timezone(channel, data, user, v)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?

        unless v.nil?
          raise SlackGamebot::Error, "#{v} is not a valid timezone, see https://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html for valid timezone names." unless ActiveSupport::TimeZone.new(v)

          channel.update_attributes!(timezone: v)
        end
        channel.slack_client.say(channel: data.channel, text: "Timezone for #{channel.slack_mention} is #{channel.timezone_s}.", gif: 'time')
        logger.info "SET: #{channel} - #{user.user_name}: timezone=#{channel.timezone_s}"
      end

      def unset_timezone(channel, data, user)
        raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

        channel.update_attributes!(timezone: 'Eastern Time (US & Canada)')
        channel.slack_client.say(channel: data.channel, text: "Timezone for #{channel.slack_mention} has been reset to #{channel.timezone_s}.", gif: 'time')
        logger.info "UNSET: #{channel} - #{user.user_name}: timezone reset to #{channel.timezone_s}"
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
        when 'won'
          set_won channel, data, user, v
        when 'api'
          set_api channel, data, user, v
        when 'elo'
          set_elo channel, data, user, v
        when 'aliases'
          set_aliases channel, data, user, v
        when 'expire'
          set_expire channel, data, user, v
        when 'remind'
          set_remind channel, data, user, v
        when 'max'
          k, v = v.split(/\s+/, 2) if v
          case k
          when 'challenges'
            set_max_challenges channel, data, user, v
          else
            raise SlackGamebot::Error, "Invalid max setting #{k}, you can _set max challenges_, _set max challenges per day_ and _set max challenges per user_."
          end
        when 'details'
          set_details channel, data, user, v
        when 'timezone'
          set_timezone channel, data, user, v
        when nil
          set_channel_info channel, data, user
        else
          raise SlackGamebot::Error, "Invalid setting #{k}, you can _set gifs on|off_, _set unbalanced on|off_, _set won on|off_, _api on|off_, _leaderboard max_, _elo_, _nickname_, _aliases_, _expire_, _remind_, _max challenges_, _max challenges per day_, _max challenges per user_ and _timezone_."
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
        when 'won'
          unset_won channel, data, user
        when 'api'
          unset_api channel, data, user
        when 'elo'
          unset_elo channel, data, user
        when 'aliases'
          unset_aliases channel, data, user
        when 'expire'
          unset_expire channel, data, user
        when 'remind'
          unset_remind channel, data, user
        when 'max'
          k, v = v.split(/\s+/, 2) if v
          case k
          when 'challenges'
            unset_max_challenges channel, data, user, v
          else
            raise SlackGamebot::Error, "Invalid max setting #{k}, you can _unset max challenges_, _unset max challenges per day_ and _unset max challenges per user_."
          end
        when 'details'
          unset_details channel, data, user
        when 'timezone'
          unset_timezone channel, data, user
        when nil
          raise SlackGamebot::Error, 'Missing setting, you can _unset gifs_, _api_, _leaderboard max_, _elo_, _nickname_, _aliases_, _expire_, _remind_, _max challenges_, _max challenges per day_, _max challenges per user_ and _timezone_.'
        else
          raise SlackGamebot::Error, "Invalid setting #{k}, you can _unset gifs_, _unset won_, _api_, _leaderboard max_, _elo_, _nickname_, _aliases_, _expire_, _remind_, _max challenges_, _max challenges per day_, _max challenges per user_ and _timezone_."
        end
      end
    end
  end
end
