module SlackGamebot
  module Commands
    class Challenges < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::Channel

      channel_command 'challenges' do |channel, data|
        challenges = channel.challenges.where(
          :state.in => [
            ChallengeState::PROPOSED,
            ChallengeState::ACCEPTED,
            ChallengeState::DRAWN
          ]
        ).asc(:created_at)

        if challenges.any?
          challenges_s = challenges.map do |challenge|
            "#{challenge} was #{challenge.state} #{(challenge.updated_at || challenge.created_at).ago_in_words}"
          end.join("\n")
          data.team.slack_client.say(channel: data.channel, text: challenges_s, gif: 'memories')
        else
          data.team.slack_client.say(channel: data.channel, text: 'All the challenges have been played.', gif: 'boring')
        end
        logger.info "CHALLENGES: #{channel} - #{data.user}"
      end
    end
  end
end
