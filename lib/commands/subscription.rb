# frozen_string_literal: true

module SlackGamebot
  module Commands
    class Subscription < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_command 'subscription' do |channel, _user, data|
        subscription_info = []
        team = data.team
        if team.stripe_subcriptions&.any?
          subscription_info << team.stripe_customer_text
          subscription_info.concat(team.stripe_customer_subscriptions_info)
          # TODO: restrict
          subscription_info.concat(team.stripe_customer_invoices_info)
          subscription_info.concat(team.stripe_customer_sources_info)
          subscription_info << team.update_cc_text
        elsif team.subscribed
          subscription_info << team.subscriber_text
        else
          subscription_info << team.trial_message
        end
        (channel || team).slack_client.say(channel: data.channel, text: subscription_info.compact.join("\n"))
        logger.info "SUBSCRIPTION: #{channel || team} - #{data.user}"
      end
    end
  end
end
