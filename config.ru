# frozen_string_literal: true

require_relative 'app'

NewRelic::Agent.manual_start

SlackGamebot::App.instance.prepare!
SlackRubyBotServer::Service.start!

run SlackGamebot::Api::Middleware.instance
