# frozen_string_literal: true

require 'slack-ruby-client'

module SlackGamebot
  module Web
    class Client < Slack::Web::Client
      attr_accessor :gifs

      def initialize(options = {})
        super
        @gifs = options[:gifs]
      end

      def gifs?
        gifs.nil? || gifs
      end

      def say(options = {})
        options = options.dup
        # get GIF
        keywords = options.delete(:gif)
        # text
        text = options.delete(:text)
        gif = Giphy.random(keywords) if keywords && gifs?
        text = [text, gif].compact.join("\n")
        chat_postMessage({ text: text }.merge(options))
      end
    end
  end
end
