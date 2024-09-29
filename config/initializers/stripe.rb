# frozen_string_literal: true

Stripe.api_key = ENV['STRIPE_API_KEY'] if ENV.key?('STRIPE_API_KEY')
