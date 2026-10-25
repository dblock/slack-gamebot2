# frozen_string_literal: true

require 'spec_helper'

describe 'Website assets', :js, type: :feature do
  it 'loads content-versioned images, generated styles and scripts on visit and reload' do
    visit '/'

    2.times do
      image = "/img/slack.png?v=#{Digest::SHA256.file('public/img/slack.png').hexdigest}"
      expect(page).to have_css("img[src='#{image}']")
      expect(page.evaluate_script('typeof jQuery')).to eq 'function'
      all('img[src^="/"]').each do |asset|
        asset.execute_script("this.scrollIntoView({block: 'center'})")
        expect(asset).to match_css('img') { |loaded| loaded.evaluate_script('this.complete && this.naturalWidth > 0') }
      end
      expect(page.evaluate_script('Array.from(document.styleSheets).some(sheet => sheet.href && /\\/styles\\.css\\?v=[a-f0-9]{64}$/.test(sheet.href) && sheet.cssRules.length > 0)')).to be true
      expect(page.evaluate_script('getComputedStyle(document.querySelector(".hero")).backgroundImage')).to include("/img/header-bg.jpg?v=#{Digest::SHA256.file('public/img/header-bg.jpg').hexdigest}")
      page.refresh
    end
  end
end
