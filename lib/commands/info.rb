module SlackGamebot
  module Commands
    class Info < Base
      def self.call(client, data, _match)
        client.say(channel: data.channel, text: SlackGamebot::INFO)
        logger.info "INFO: #{client.owner} - #{data.user}"
      end
    end
  end
end
