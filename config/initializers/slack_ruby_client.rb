require 'slack-ruby-client'

module SlackGamebot
  module Web
    class Client < Slack::Web::Client
      attr_accessor :send_gifs, :aliases
      attr_reader :owner

      def initialize(options = {})
        super
        @owner = options[:team] if options && options.key?(:team)
        @send_gifs = options[:send_gifs]
        @aliases = options[:aliases]
      end

      def send_gifs?
        send_gifs.nil? ? true : send_gifs
      end

      def say(options = {})
        options = options.dup
        # get GIF
        keywords = options.delete(:gif)
        # text
        text = options.delete(:text)
        gif = Giphy.random(keywords) if keywords && send_gifs?
        text = [text, gif].compact.join("\n")
        chat_postMessage({ text: text }.merge(options))
      end
    end
  end
end
