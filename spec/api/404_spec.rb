# frozen_string_literal: true

require 'spec_helper'

describe Api do
  include Api::Test::EndpointTest

  context '404' do
    it 'returns a plain 404' do
      get '/api/foobar'
      expect(last_response.status).to eq 404
      expect(last_response.body).to eq '404 Not Found'
    end
  end
end
