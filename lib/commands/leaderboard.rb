module SlackGamebot
  module Commands
    class Leaderboard < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::Channel

      channel_command 'leaderboard' do |channel, data, _match|
        max = channel.leaderboard_max
        reverse = false
        arguments = data.match['expression'].split.reject(&:blank?) if data.match['expression']
        arguments ||= []
        number = arguments.shift
        if number
          if number[0] == '-'
            reverse = true
            number = number[1..-1]
          end
          max = case number.downcase
                when 'infinity'
                  nil
                else
                  Integer(number)
                end
        end
        ranked_players = channel.users.ranked
        if ranked_players.any?
          ranked_players = ranked_players.send(reverse ? :desc : :asc, :rank)
          ranked_players = ranked_players.limit(max) if max && max >= 1
          message = ranked_players.each_with_index.map do |user, index|
            "#{reverse ? index + 1 : user.rank}. #{user}"
          end.join("\n")
          data.team.slack_client.say(channel: data.channel, text: message)
        else
          data.team.slack_client.say(channel: data.channel, text: "There're no ranked players.", gif: 'empty')
        end
        logger.info "LEADERBOARD #{max || '∞'}: #{channel} - #{data.user}"
      end
    end
  end
end
