module SlackGamebot
  module Commands
    class Hi < Base
      def self.call(client, data, _match)
        client.say(channel: data.channel, gif: 'hello', text: "Hi <@#{data.user}>!")
        logger.info "HI: #{client.owner} - #{data.user}"
      end
    end
  end
end
