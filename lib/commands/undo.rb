# frozen_string_literal: true

module SlackGamebot
  module Commands
    class Undo < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'undo' do |channel, user, data|
        recent = Match.current.where(channel: channel, :created_at.gte => 1.hour.ago)
        match = recent.any_of({ winner_ids: user._id }, { loser_ids: user._id }).desc(:_id).first
        match ||= recent.desc(:_id).first if user.captain?
        raise SlackGamebot::Error, 'No match to undo.' unless match

        match_s = match.to_s
        match.undo!
        channel.slack_client.say(channel: data.channel, text: "Match #{match_s} has been undone.", gif: 'undo')
        logger.info "UNDO: #{channel} - #{user.user_name}: #{match_s}"
      end
    end
  end
end
