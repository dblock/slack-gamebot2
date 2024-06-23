module SlackGamebot
  module Commands
    class Lost < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'lost' do |channel, challenger, data|
        expression = data.match['expression'] if data.match['expression']
        arguments = expression.split.reject(&:blank?) if expression

        scores = nil
        opponents = []
        teammates = [challenger]
        multi_player = expression&.include?(' with ')

        current = :scores
        while arguments&.any?
          argument = arguments.shift
          case argument
          when 'to'
            current = :opponents
          when 'with'
            current = :teammates
          else
            if current == :opponents
              opponents << channel.find_or_create_by_mention!(argument)
              current = :scores unless multi_player
            elsif current == :teammates
              teammates << channel.find_or_create_by_mention!(argument)
              current = :scores if opponents.count == teammates.count
            else
              scores ||= []
              scores << Score.check(argument)
            end
          end
        end

        challenge = ::Challenge.find_by_user(challenger, [ChallengeState::PROPOSED, ChallengeState::ACCEPTED])

        if !(teammates & opponents).empty?
          data.team.slack_client.say(channel: data.channel, text: 'You cannot lose to yourself!', gif: 'loser')
          logger.info "LOST TO: #{channel} - SELF"
        elsif opponents.any? && (challenge.nil? || (challenge.challengers != opponents && challenge.challenged != opponents))
          match = ::Match.lose!(team: channel.team, channel: channel, winners: opponents, losers: teammates, scores: scores)
          data.team.slack_client.say(channel: data.channel, text: "Match has been recorded! #{match}.", gif: 'loser')
          logger.info "LOST TO: #{channel} - #{match}"
        elsif challenge
          challenge.lose!(challenger, scores)
          data.team.slack_client.say(channel: data.channel, text: "Match has been recorded! #{challenge.match}.", gif: 'loser')
          logger.info "LOST: #{channel} - #{challenge}"
        else
          match = ::Match.where(loser_ids: challenger.id).desc(:_id).first
          if match
            match.update_attributes!(scores: scores)
            data.team.slack_client.say(channel: data.channel, text: "Match scores have been updated! #{match}.", gif: 'score')
            logger.info "SCORED: #{channel} - #{match}"
          else
            data.team.slack_client.say(channel: data.channel, text: 'No challenge to lose!')
            logger.info "LOST: #{channel} - #{data.user}, N/A"
          end
        end
      end
    end
  end
end
