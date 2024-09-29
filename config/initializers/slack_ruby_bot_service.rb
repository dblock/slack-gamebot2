# frozen_string_literal: true

module SlackRubyBotServer
  class Service
    def self.url
      ENV.fetch('URL') { (ENV['RACK_ENV'] == 'development' ? 'http://localhost:5000' : 'https://gamebot2.playplay.io') }
    end

    def self.api_url
      ENV.fetch('API_URL') { "#{url}/api" }
    end
  end
end
