# frozen_string_literal: true

require 'spec_helper'

describe 'Website', :js, type: :feature do
  it 'keeps the original background photograph and loads the Slack demonstration' do
    visit '/'
    background = page.evaluate_script("getComputedStyle(document.querySelector('.hero')).backgroundImage")
    expect(background).to include("/img/header-bg.jpg?v=#{Digest::SHA256.file('public/img/header-bg.jpg').hexdigest}")
    expect(page).to have_css('.hero-preview img[src^="/img/slack.png?v="]') do |image|
      image.evaluate_script('this.complete && this.naturalWidth > 0')
    end
    expect(page).to have_css('#pricing .price', text: '$49.99')
  end

  it 'opens and closes game instructions with the keyboard' do
    visit '/help.html'
    within('details', text: 'How do I challenge a teammate?') do
      expect(page).to have_no_css('p')
      find('summary').send_keys(:enter)
      expect(page).to have_css('p', text: '@gamebot challenge @opponent')
      find('summary').send_keys(:enter)
      expect(page).to have_no_css('p')
    end
  end

  it 'keeps the product demonstration and navigation usable at 320 pixels' do
    visit '/'
    page.execute_script("document.body.innerHTML = '<iframe id=\"mobile\" title=\"Mobile\" src=\"/\" width=\"320\" style=\"border:0\"></iframe>'")
    within_frame('mobile') do
      expect(page.evaluate_script('window.innerWidth')).to eq 320
      expect(page).to have_css('.hero-preview img') { |image| image.evaluate_script('this.complete && this.naturalWidth > 0') }
      expect(page).to have_css('html') { |html| html.evaluate_script('this.scrollWidth <= window.innerWidth') }
      within('nav') { click_link 'Help' }
      expect(page).to have_css('h1', exact_text: 'Help')
      within('#command-reference') do
        find('summary', text: 'gamebot set max games per user [number|none]', exact_text: true).send_keys(:enter)
        expect(page).to have_css('pre', text: 'gamebot set max games per user 2')
      end
      expect(page).to have_css('html') { |html| html.evaluate_script('this.scrollWidth <= window.innerWidth') }
    end
  end

  it 'includes every README command plus the remaining Slack help commands' do
    commands = File.readlines('README.md').grep(/^#### /).map { |line| CGI.unescapeHTML(line.delete_prefix('#### ').strip) }
    commands += ['gamebot channels', 'gamebot set token [token]']
    visit '/help.html'
    within('#command-reference') do
      expect(all('summary').map(&:text)).to include(*commands)
    end
  end

  it 'shares the layout without changing the privacy policy' do
    visit '/privacy.html'
    expect(page).to have_css('h1', text: 'PlayPlay.io Privacy Policy')
    expect(page).to have_text('After you no longer use our Service we keep data for 7 years')
    expect(page).to have_link('Pricing', href: '/#pricing')
  end
end
