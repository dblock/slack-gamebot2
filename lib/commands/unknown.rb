# frozen_string_literal: true

module SlackGamebot
  module Commands
    class Unknown < Base
      match(/^(?<bot>\S*)[\s]*(?<expression>.*)$/)

      def self.call(client, data, _match)
        client.say(channel: data.channel, gif: 'understand', text: "Sorry <@#{data.user}>, I don't understand that command!")
      end
    end
  end
end
