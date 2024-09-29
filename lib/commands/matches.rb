# frozen_string_literal: true

module SlackGamebot
  module Commands
    class Matches < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::Channel

      channel_command 'matches' do |channel, data, _match|
        totals = {}
        totals.default = 0
        arguments = data.match['expression'].split.reject(&:blank?) if data.match['expression']
        # limit
        max = 10
        if arguments&.any?
          case arguments.last.downcase
          when 'infinity'
            max = nil
          else
            begin
              Integer(arguments.last).tap do |value|
                max = value
                arguments.pop
              end
            rescue ArgumentError
              # ignore
            end
          end
        end
        # users
        users = channel.find_or_create_many_by_mention!(arguments) if arguments&.any?
        user_ids = users.map(&:id) if users&.any?
        matches = channel.matches.current
        matches = matches.any_of({ :winner_ids.in => user_ids }, :loser_ids.in => user_ids) if user_ids&.any?
        matches.each do |m|
          totals[m.to_s] += 1
        end
        totals = totals.sort_by { |_, value| -value }
        totals = totals.take(max) if max
        message = totals.map do |s, count|
          case count
          when 1
            "#{s} once"
          when 2
            "#{s} twice"
          else
            "#{s} #{count} times"
          end
        end.join("\n")
        channel.slack_client.say(channel: data.channel, text: message.empty? ? 'No matches.' : message)
        logger.info "MATCHES: #{channel} - #{data.user}"
      end
    end
  end
end
