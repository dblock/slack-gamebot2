# frozen_string_literal: true

module SlackGamebot
  module Commands
    class Games < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::Channel

      channel_command 'games' do |channel, data, _match|
        arguments = data.match['expression'].split.reject(&:blank?) if data.match['expression']
        users = channel.find_or_create_many_by_mention!(arguments) if arguments&.any?
        players = users&.any? ? users : channel.users.where(:wins.gt => 0).or(:losses.gt => 0).or(:ties.gt => 0)
        players = players.sort_by { |u| -(u.wins + u.losses + u.ties) }
        total = players.sum { |u| u.wins + u.losses + u.ties }
        if players.none?
          channel.slack_client.say(channel: data.channel, text: 'No games have been played.', gif: 'empty')
        else
          lines = ["A total of #{total} game#{'s' unless total == 1} #{total == 1 ? 'has' : 'have'} been played."]
          lines += players.map do |u|
            wins_s = "#{u.wins} win#{'s' unless u.wins == 1}"
            losses_s = "#{u.losses} loss#{'es' unless u.losses == 1}"
            ties_s = "#{u.ties} tie#{'s' unless u.ties == 1}" if u.ties&.positive?
            "#{u.display_name}: #{[wins_s, losses_s, ties_s].compact.join(', ')}"
          end
          channel.slack_client.say(channel: data.channel, text: lines.join("\n"))
        end
        logger.info "GAMES: #{channel} - #{data.user}"
      end
    end
  end
end
