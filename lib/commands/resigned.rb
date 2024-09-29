# frozen_string_literal: true

module SlackGamebot
  module Commands
    class Resigned < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'resigned' do |channel, challenger, data|
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
              scores << argument
            end
          end
        end

        challenge = ::Challenge.find_by_user(challenger, [ChallengeState::PROPOSED, ChallengeState::ACCEPTED])

        if scores&.any?
          channel.slack_client.say(channel: data.channel, text: 'Cannot score when resigning.', gif: 'idiot')
          logger.info "RESIGNED: #{channel} - #{data.user}, cannot score."
        elsif opponents.any? && (challenge.nil? || (challenge.challengers != opponents && challenge.challenged != opponents))
          match = ::Match.resign!(team: channel.team, channel: channel, winners: opponents, losers: teammates)
          channel.slack_client.say(channel: data.channel, text: "Match has been recorded! #{match}.", gif: 'loser')
          logger.info "RESIGNED TO: #{channel} - #{match}"
        elsif challenge
          challenge.resign!(challenger)
          channel.slack_client.say(channel: data.channel, text: "Match has been recorded! #{challenge.match}.", gif: 'loser')
          logger.info "RESIGNED: #{channel} - #{challenge}"
        else
          channel.slack_client.say(channel: data.channel, text: 'No challenge to resign!')
          logger.info "RESIGNED: #{channel} - #{data.user}, N/A"
        end
      end
    end
  end
end
