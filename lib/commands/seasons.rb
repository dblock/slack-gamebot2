# frozen_string_literal: true

module SlackGamebot
  module Commands
    class Seasons < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::Channel

      channel_command 'seasons' do |channel, data|
        current_season = ::Season.new(team: channel.team, channel: channel)
        if current_season.valid?
          message = [current_season, channel.seasons.desc(:_id)].flatten.map(&:to_s).join("\n")
          channel.slack_client.say(channel: data.channel, text: message)
        elsif ::Season.where(channel: channel).any? # don't use channel.seasons, would include current_season
          message = channel.seasons.desc(:_id).map(&:to_s).join("\n")
          channel.slack_client.say(channel: data.channel, text: message)
        else
          channel.slack_client.say(channel: data.channel, text: "There're no seasons.", gif: %w[winter summer fall spring].sample)
        end
        logger.info "SEASONS: #{channel} - #{data.user}"
      end
    end
  end
end
