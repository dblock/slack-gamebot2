# frozen_string_literal: true

require 'spec_helper'
require 'nokogiri'

describe Api do
  include Api::Test::EndpointTest

  it 'returns a sitemap.xml with indexable public pages' do
    get '/sitemap.xml'
    expect(last_response.status).to eq 200
    expect(last_response.headers['Content-Type']).to include 'application/xml'
    expect(last_response.body).to include '<loc>https://gamebot2.playplay.io/</loc>'
    expect(last_response.body).to include '<loc>https://gamebot2.playplay.io/privacy.html</loc>'
  end

  it 'returns valid, well-formed XML' do
    get '/sitemap.xml'
    doc = Nokogiri::XML(last_response.body, &:strict)
    expect(doc.errors).to be_empty
    expect(doc.root.name).to eq 'urlset'
  end
end
