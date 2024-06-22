# frozen_string_literal: true

require_relative 'support/match'

module SlackGamebot
  module Commands
    class Base
      include SlackRubyBotServer::Loggable

      class << self
        attr_accessor :command_classes

        def inherited(subclass)
          SlackGamebot::Commands::Base.command_classes ||= []
          SlackGamebot::Commands::Base.command_classes << subclass
        end

        def call(client, data)
          command_classes.detect { |d| d.invoke(client, data) }
        end

        def command(*values, &block)
          values = values.map { |value| value.is_a?(Regexp) ? value.source : Regexp.escape(value) }.join('|')
          match Regexp.new("^[@?]gamebot[[:space:]](?<command>#{values})([[:space:]]+(?<expression>.*)|)$", Regexp::IGNORECASE | Regexp::MULTILINE), &block
        end

        def invoke(client, data)
          _invoke client, data
        rescue Mongoid::Errors::Validations => e
          logger.info "#{name.demodulize.upcase}: #{client.owner}, error - #{e.document.class}, #{e.document.errors.to_hash}"
          client.say(channel: data.channel, text: e.document.errors.map(&:type).join("\n"))
          true
        rescue StandardError => e
          logger.info "#{name.demodulize.upcase}: #{client.owner}, #{e.class}: #{e}"
          logger.debug e.backtrace.join("\n")
          client.say(channel: data.channel, text: e.message)
          true
        end

        def _invoke(client, data)
          finalize_routes!

          expression = data.text

          routes.each_pair do |route, options|
            match_method = options[:match_method]
            case match_method
            when :match
              next unless expression

              match = route.match(expression)
              next unless match

              match = Support::Match.new(match)
            when :scan
              next unless expression

              match = expression.scan(route)
              next unless match.any?
            end
            call_command(client, data, match, options[:block])
            return true
          end
          false
        end

        def match(match, &block)
          routes[match] = { match_method: :match, block: block }
        end

        def scan(match, &block)
          routes[match] = { match_method: :scan, block: block }
        end

        def routes
          @routes ||= ActiveSupport::OrderedHash.new
        end

        private

        def call_command(client, data, match, block)
          if block
            block.call(client, data, match) if permitted?(client, data, match)
          elsif respond_to?(:call)
            send(:call, client, data, match) if permitted?(client, data, match)
          else
            raise NotImplementedError, data.text
          end
        end

        def direct_message?(data)
          data.channel && data.channel[0] == 'D'
        end

        def finalize_routes!
          return if routes&.any?

          command command_name_from_class
        end

        def command_name_from_class
          name ? name.split(':').last.downcase : object_id.to_s
        end

        # Intended to be overridden by subclasses to hook in an
        # authorization mechanism.
        def permitted?(_client, _data, _match)
          true
        end
      end
    end
  end
end
