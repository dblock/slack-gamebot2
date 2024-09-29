# frozen_string_literal: true

module SlackGamebot
  module Commands
    module Mixins
      module Rescue
        extend ActiveSupport::Concern

        module ClassMethods
          def with_rescue(team_or_channel, user, data, &_block)
            yield team_or_channel, user, data
          rescue Mongoid::Errors::Validations => e
            errors = e.document.errors.messages.transform_values(&:uniq).values.join("\n")
            team_or_channel.slack_client.say channel: data.channel, text: errors
            logger.warn "#{team_or_channel}, user=#{data.user}, text=#{errors}"
          rescue SlackGamebot::Error => e
            team_or_channel.slack_client.say channel: data.channel, text: e.message
            logger.warn "#{team_or_channel}, user=#{data.user}, text=#{e.message}"
          end
        end
      end
    end
  end
end
