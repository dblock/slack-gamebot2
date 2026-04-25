# frozen_string_literal: true

module SlackGamebot
  module Commands
    class Channels < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::DM

      dm_command 'channels' do |team, data|
        channels = team.channels.enabled.where(is_app_home: false).asc(:created_at)
        if channels.none?
          team.slack_client.say(channel: data.channel, text: "No channels. To start a leaderboard, invite me to a channel with `/invite #{team.bot_mention}`.")
        else
          message = channels.map do |c|
            match_count = c.matches.current.count
            player_count = c.users.ranked.count
            season_count = c.seasons.count
            parts = [
              "#{match_count} match#{'es' unless match_count == 1}",
              "#{player_count} player#{'s' unless player_count == 1}",
              "#{season_count} season#{'s' unless season_count == 1}"
            ]
            "#{c.slack_mention}: #{parts.join(', ')}"
          end.join("\n")
          team.slack_client.say(channel: data.channel, text: message)
        end
        logger.info "CHANNELS: #{team} - #{data.user}"
      end
    end
  end
end
