# frozen_string_literal: true

module SlackGamebot
  module Commands
    class Draw < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'draw' do |channel, challenger, data|
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

        challenge = ::Challenge.find_by_user(challenger,
                                             [
                                               ChallengeState::PROPOSED,
                                               ChallengeState::ACCEPTED,
                                               ChallengeState::DRAWN
                                             ])

        if !(teammates & opponents).empty?
          channel.slack_client.say(channel: data.channel, text: 'You cannot draw to yourself!', gif: 'loser')
          logger.info "Cannot draw to yourself: #{channel} - #{match}"
        elsif opponents.any? && (challenge.nil? || (challenge.challengers != opponents && challenge.challenged != opponents))
          challenge = ::Challenge.create!(
            team: channel.team,
            channel: channel,
            created_by: challenger,
            updated_by: challenger,
            challengers: teammates,
            challenged: opponents,
            draw: [challenger],
            draw_scores: scores,
            state: ChallengeState::DRAWN
          )
          messages = [
            "Match is a draw, waiting to hear from #{(challenge.challengers + challenge.challenged - challenge.draw).map(&:display_name).and}.",
            challenge.draw_scores? ? "Recorded #{Score.scores_to_string(challenge.draw_scores)}." : nil
          ].compact
          channel.slack_client.say(channel: data.channel, text: messages.join(' '), gif: 'tie')
          logger.info "DRAW TO: #{channel} - #{challenge}"
        elsif challenge
          if challenge.draw.include?(challenger)
            challenge.update_attributes!(draw_scores: scores) if scores
            messages = [
              "Match is a draw, still waiting to hear from #{(challenge.challengers + challenge.challenged - challenge.draw).map(&:display_name).and}.",
              challenge.draw_scores? ? "Recorded #{Score.scores_to_string(challenge.draw_scores)}." : nil
            ].compact
            channel.slack_client.say(channel: data.channel, text: messages.join(' '), gif: 'tie')
          else
            challenge.draw!(challenger, scores)
            if challenge.state == ChallengeState::PLAYED
              channel.slack_client.say(channel: data.channel, text: "Match has been recorded! #{challenge.match}.", gif: 'tie')
            else
              messages = [
                "Match is a draw, waiting to hear from #{(challenge.challengers + challenge.challenged - challenge.draw).map(&:display_name).and}.",
                challenge.draw_scores? ? "Recorded #{Score.scores_to_string(challenge.draw_scores)}." : nil
              ].compact
              channel.slack_client.say(channel: data.channel, text: messages.join(' '), gif: 'tie')
            end
          end
          logger.info "DRAW: #{channel} - #{challenge}"
        else
          match = ::Match.any_of({ winner_ids: challenger.id }, loser_ids: challenger.id).desc(:id).first
          if match&.tied?
            match.update_attributes!(scores: scores)
            channel.slack_client.say(channel: data.channel, text: "Match scores have been updated! #{match}.", gif: 'score')
            logger.info "SCORED: #{channel} - #{match}"
          else
            channel.slack_client.say(channel: data.channel, text: 'No challenge to draw!')
            logger.info "DRAW: #{channel} - #{data.user}, N/A"
          end
        end
      end
    end
  end
end
