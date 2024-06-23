module SlackGamebot
  module Commands
    class Promote < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'promote' do |channel, user, data|
        arguments = data.match['expression'].split.reject(&:blank?) if data.match['expression']
        users = channel.find_or_create_many_by_mention!(arguments) if arguments&.any?
        captains = users.select(&:captain) if users
        if !users
          data.team.slack_client.say(channel: data.channel, text: 'Try _promote @someone_.', gif: 'help')
          logger.info "PROMOTE: #{channel} - #{user.user_name}, failed, no users"
        elsif !user.captain?
          data.team.slack_client.say(channel: data.channel, text: "You're not a captain, sorry.", gif: 'sorry')
          logger.info "PROMOTE: #{channel} - #{user.user_name} promoting #{users.map(&:display_name).and}, failed, not captain"
        elsif captains && captains.count > 1
          data.team.slack_client.say(channel: data.channel, text: "#{captains.map(&:display_name).and} are already captains.")
          logger.info "PROMOTE: #{channel} - #{user.user_name} promoting #{users.map(&:display_name).and}, failed, #{captains.map(&:display_name).and} already captains"
        elsif captains && captains.count == 1
          data.team.slack_client.say(channel: data.channel, text: "#{captains.first.user_name} is already a captain.")
          logger.info "PROMOTE: #{channel} - #{user.user_name} promoting #{users.map(&:display_name).and}, failed, #{captains.first.user_name} already captain"
        else
          users.each(&:promote!)
          data.team.slack_client.say(channel: data.channel, text: "#{users.map(&:display_name).and} #{users.count == 1 ? 'has' : 'have'} been promoted to captain.", gif: 'power')
          logger.info "PROMOTE: #{channel} - #{user.user_name} promoted #{users.map(&:display_name).and}"
        end
      end
    end
  end
end
