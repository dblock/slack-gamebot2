# frozen_string_literal: true

module SlackGamebot
  module Commands
    class Won < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'won' do |channel, winner, data|
        raise SlackGamebot::Error, "The won command is disabled for #{channel.slack_mention}." unless channel.won?

        expression = data.match['expression'] if data.match['expression']
        arguments = expression.split.reject(&:blank?) if expression

        scores = nil
        opponents = []
        teammates = [winner]
        multi_player = expression&.include?(' with ')

        current = :scores
        while arguments&.any?
          argument = arguments.shift
          case argument
          when 'against'
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
              scores << Score.check(argument).reverse
            end
          end
        end

        challenge = ::Challenge.find_by_user(winner, [ChallengeState::ACCEPTED])

        if !(teammates & opponents).empty?
          channel.slack_client.say(channel: data.channel, text: 'You cannot win against yourself!', gif: 'winner')
          logger.info "WON AGAINST: #{channel} - SELF"
        elsif opponents.any? && (challenge.nil? || (challenge.challengers != opponents && challenge.challenged != opponents))
          match = ::Match.lose!(team: channel.team, channel: channel, winners: teammates, losers: opponents, scores: scores)
          rc = channel.slack_client.say(channel: data.channel, text: "Match has been recorded! #{match}.", gif: 'winner')
          channel.slack_client.chat_postMessage(channel: data.channel, text: channel.leaderboard_s, thread_ts: rc['ts']) if rc.key?('ts') && channel.details.include?(Details::LEADERBOARD)
          logger.info "WON AGAINST: #{channel} - #{match}"
        elsif challenge
          challenge.win!(winner, scores)
          rc = channel.slack_client.say(channel: data.channel, text: "Match has been recorded! #{challenge.match}.", gif: 'winner')
          channel.slack_client.chat_postMessage(channel: data.channel, text: channel.leaderboard_s, thread_ts: rc['ts']) if rc.key?('ts') && channel.details.include?(Details::LEADERBOARD)
          logger.info "WON: #{channel} - #{challenge}"
        else
          match = ::Match.where(winner_ids: winner.id).desc(:_id).first
          if match
            match.update_attributes!(scores: scores)
            channel.slack_client.say(channel: data.channel, text: "Match scores have been updated! #{match}.", gif: 'score')
            logger.info "SCORED: #{channel} - #{match}"
          else
            channel.slack_client.say(channel: data.channel, text: 'No challenge to win!')
            logger.info "WON: #{channel} - #{data.user}, N/A"
          end
        end
      end
    end
  end
end
