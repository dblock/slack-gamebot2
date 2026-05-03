# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Commands::SetChannel do
  include_context 'user'

  let(:captain) { Fabricate(:user, channel: channel, captain: true) }

  context 'captain' do
    before do
      user.update_attributes!(captain: true)
    end

    context 'gifs' do
      it 'shows current value of GIFs on' do
        expect(message: '@gamebot set gifs', user: captain, channel: channel).to respond_with_slack_message(
          "GIFs for #{channel.slack_mention} are on!"
        )
      end

      it 'shows current value of GIFs off' do
        channel.update_attributes!(gifs: false)
        expect(message: '@gamebot set gifs', user: captain, channel: channel).to respond_with_slack_message(
          "GIFs for #{channel.slack_mention} are off."
        )
      end

      it 'enables GIFs' do
        channel.update_attributes!(gifs: false)
        expect(message: '@gamebot set gifs on', user: captain, channel: channel).to respond_with_slack_message(
          "GIFs for #{channel.slack_mention} are on!"
        )
        expect(channel.reload.gifs).to be true
      end

      it 'disables GIFs with set' do
        channel.update_attributes!(gifs: true)
        expect(message: '@gamebot set gifs off', user: captain, channel: channel).to respond_with_slack_message(
          "GIFs for #{channel.slack_mention} are off."
        )
        expect(channel.reload.gifs).to be false
      end

      it 'disables GIFs with unset' do
        channel.update_attributes!(gifs: true)
        expect(message: '@gamebot unset gifs', user: captain, channel: channel).to respond_with_slack_message(
          "GIFs for #{channel.slack_mention} are off."
        )
        expect(channel.reload.gifs).to be false
      end
    end

    context 'unbalanced' do
      it 'shows current value of unbalanced off' do
        channel.update_attributes!(unbalanced: false)
        expect(message: '@gamebot set unbalanced', user: captain, channel: channel).to respond_with_slack_message(
          "Unbalanced challenges for #{channel.slack_mention} are off."
        )
      end

      it 'enables unbalanced' do
        channel.update_attributes!(unbalanced: false)
        expect(message: '@gamebot set unbalanced on', user: captain, channel: channel).to respond_with_slack_message(
          "Unbalanced challenges for #{channel.slack_mention} are on!"
        )
        expect(channel.reload.unbalanced).to be true
      end

      it 'disables unbalanced with set' do
        channel.update_attributes!(unbalanced: true)
        expect(message: '@gamebot set unbalanced off', user: captain, channel: channel).to respond_with_slack_message(
          "Unbalanced challenges for #{channel.slack_mention} are off."
        )
        expect(channel.reload.unbalanced).to be false
      end

      it 'disables unbalanced with unset' do
        channel.update_attributes!(unbalanced: true)
        expect(message: '@gamebot unset unbalanced', user: captain, channel: channel).to respond_with_slack_message(
          "Unbalanced challenges for #{channel.slack_mention} are off."
        )
        expect(channel.reload.unbalanced).to be false
      end
    end

    context 'won' do
      it 'shows current value of won on' do
        channel.update_attributes!(won: true)
        expect(message: '@gamebot set won', user: captain, channel: channel).to respond_with_slack_message(
          "Won command for #{channel.slack_mention} is on!"
        )
      end

      it 'shows current value of won off' do
        channel.update_attributes!(won: false)
        expect(message: '@gamebot set won', user: captain, channel: channel).to respond_with_slack_message(
          "Won command for #{channel.slack_mention} is off."
        )
      end

      it 'enables won' do
        channel.update_attributes!(won: false)
        expect(message: '@gamebot set won on', user: captain, channel: channel).to respond_with_slack_message(
          "Won command for #{channel.slack_mention} is on!"
        )
        expect(channel.reload.won).to be true
      end

      it 'disables won with set' do
        channel.update_attributes!(won: true)
        expect(message: '@gamebot set won off', user: captain, channel: channel).to respond_with_slack_message(
          "Won command for #{channel.slack_mention} is off."
        )
        expect(channel.reload.won).to be false
      end

      it 'disables won with unset' do
        channel.update_attributes!(won: true)
        expect(message: '@gamebot unset won', user: captain, channel: channel).to respond_with_slack_message(
          "Won command for #{channel.slack_mention} is off."
        )
        expect(channel.reload.won).to be false
      end
    end

    context 'api' do
      it 'shows current value of API on' do
        channel.update_attributes!(api: true)
        expect(message: '@gamebot set api', user: captain, channel: channel).to respond_with_slack_message(
          "API for #{channel.slack_mention} is on!\nDM the bot _set token_ to get or set an API token to pass as an `X-Access-Token` header to #{channel.api_url}."
        )
      end

      it 'shows current value of API off' do
        channel.update_attributes!(api: false)
        expect(message: '@gamebot set api', user: captain, channel: channel).to respond_with_slack_message(
          "API for #{channel.slack_mention} is off."
        )
      end

      it 'enables API' do
        expect(message: '@gamebot set api on', user: captain, channel: channel).to respond_with_slack_message(
          "API for #{channel.slack_mention} is on!\nDM the bot _set token_ to get or set an API token to pass as an `X-Access-Token` header to #{channel.api_url}."
        )
        expect(channel.reload.api).to be true
      end

      it 'disables API with set' do
        channel.update_attributes!(api: true)
        expect(message: '@gamebot set api off', user: captain, channel: channel).to respond_with_slack_message(
          "API for #{channel.slack_mention} is off."
        )
        expect(channel.reload.api).to be false
      end

      it 'disables API with unset' do
        channel.update_attributes!(api: true)
        expect(message: '@gamebot unset api', user: captain, channel: channel).to respond_with_slack_message(
          "API for #{channel.slack_mention} is off."
        )
        expect(channel.reload.api).to be false
      end

      context 'with API_URL' do
        before do
          ENV['API_URL'] = 'http://local.api'
        end

        after do
          ENV.delete 'API_URL'
        end

        it 'shows current value of API on with API URL' do
          channel.update_attributes!(api: true)
          expect(message: '@gamebot set api', user: captain, channel: channel).to respond_with_slack_message(
            "API for #{channel.slack_mention} is on!\nDM the bot _set token_ to get or set an API token to pass as an `X-Access-Token` header to http://local.api/channels/#{channel.id}."
          )
        end

        it 'shows current value of API off without API URL' do
          channel.update_attributes!(api: false)
          expect(message: '@gamebot set api', user: captain, channel: channel).to respond_with_slack_message(
            "API for #{channel.slack_mention} is off."
          )
        end
      end
    end

    context 'aliases' do
      context 'with aliases' do
        before do
          channel.update_attributes!(aliases: %w[foo bar])
        end

        it 'shows current value of aliases' do
          expect(message: '@gamebot set aliases', user: captain, channel: channel).to respond_with_slack_message(
            "Bot aliases for #{channel.slack_mention} are `foo` and `bar`."
          )
        end

        it 'sets aliases' do
          expect(message: '@gamebot set aliases foo bar baz', user: captain, channel: channel).to respond_with_slack_message(
            "Bot aliases for #{channel.slack_mention} are `foo`, `bar` and `baz`."
          )
          expect(channel.reload.aliases).to eq %w[foo bar baz]
        end

        it 'sets comma-separated aliases' do
          expect(message: '@gamebot set aliases foo,bar', user: captain, channel: channel).to respond_with_slack_message(
            "Bot aliases for #{channel.slack_mention} are `foo` and `bar`."
          )
          expect(channel.reload.aliases).to eq %w[foo bar]
        end

        it 'sets comma-separated aliases with extra spaces' do
          expect(message: '@gamebot set aliases   foo,    bar', user: captain, channel: channel).to respond_with_slack_message(
            "Bot aliases for #{channel.slack_mention} are `foo` and `bar`."
          )
          expect(channel.reload.aliases).to eq %w[foo bar]
        end

        it 'sets emoji aliases' do
          expect(message: '@gamebot set aliases pp :pong:', user: captain, channel: channel).to respond_with_slack_message(
            "Bot aliases for #{channel.slack_mention} are `pp` and `:pong:`."
          )
          expect(channel.reload.aliases).to eq ['pp', ':pong:']
        end

        it 'removes aliases' do
          expect(message: '@gamebot unset aliases', user: captain, channel: channel).to respond_with_slack_message(
            "#{channel.slack_mention} no longer has bot aliases."
          )
          expect(channel.reload.aliases).to be_empty
        end
      end

      context 'without aliases' do
        before do
          channel.update_attributes!(aliases: [])
        end

        it 'shows no aliases' do
          expect(message: '@gamebot set aliases', user: captain, channel: channel).to respond_with_slack_message(
            "#{channel.slack_mention} does not have any bot aliases."
          )
        end
      end
    end

    context 'details' do
      context 'with details' do
        before do
          channel.update_attributes!(details: %w[elo])
        end

        it 'shows current value of details' do
          expect(message: '@gamebot set details', user: captain, channel: channel).to respond_with_slack_message(
            "Match details for #{channel.slack_mention} are `elo`."
          )
        end

        it 'sets details' do
          expect(message: '@gamebot set details elo leaderboard', user: captain, channel: channel).to respond_with_slack_message(
            "Match details for #{channel.slack_mention} are `elo` and `leaderboard`."
          )
          expect(channel.reload.details).to eq %w[elo leaderboard]
        end

        it 'removes details using unset' do
          expect(message: '@gamebot unset details', user: captain, channel: channel).to respond_with_slack_message(
            "Match details for #{channel.slack_mention} are not shown."
          )
          expect(channel.reload.details).to be_empty
        end

        it 'removes details using set' do
          expect(message: '@gamebot set details none', user: captain, channel: channel).to respond_with_slack_message(
            "Match details for #{channel.slack_mention} are not shown."
          )
          expect(channel.reload.details).to be_empty
        end

        it 'handles errors' do
          expect(message: '@gamebot set details invalid', user: captain, channel: channel).to respond_with_slack_message(
            'Invalid value: invalid, possible values are elo and leaderboard.'
          )
          expect(channel.reload.details).to eq ['elo']
        end
      end

      context 'without details' do
        before do
          channel.update_attributes!(details: [])
        end

        it 'shows no details' do
          expect(message: '@gamebot set details', user: captain, channel: channel).to respond_with_slack_message(
            "Match details for #{channel.slack_mention} are not shown."
          )
        end
      end
    end

    context 'elo' do
      context 'with a non-default base elo' do
        before do
          channel.update_attributes!(elo: 1000)
        end

        it 'shows current value of elo' do
          expect(message: '@gamebot set elo', user: captain, channel: channel).to respond_with_slack_message(
            "Base elo for #{channel.slack_mention} is 1000."
          )
        end

        it 'sets elo' do
          expect(message: '@gamebot set elo 200', user: captain, channel: channel).to respond_with_slack_message(
            "Base elo for #{channel.slack_mention} is 200."
          )
          expect(channel.reload.elo).to eq 200
        end

        it 'handles errors' do
          expect(message: '@gamebot set elo invalid', user: captain, channel: channel).to respond_with_slack_message(
            'Sorry, invalid is not a valid number.'
          )
          expect(channel.reload.elo).to eq 1000
        end

        it 'resets elo with set' do
          expect(message: '@gamebot set elo 0', user: captain, channel: channel).to respond_with_slack_message(
            "Base elo for #{channel.slack_mention} is 0."
          )
          expect(channel.reload.elo).to eq 0
        end

        it 'resets elo with unset' do
          expect(message: '@gamebot unset elo', user: captain, channel: channel).to respond_with_slack_message(
            "Base elo for #{channel.slack_mention} has been unset."
          )
          expect(channel.reload.elo).to eq 0
        end
      end

      context 'algorithm' do
        it 'shows current algorithm' do
          expect(message: '@gamebot set elo algorithm', user: captain, channel: channel).to respond_with_slack_message(
            "Elo algorithm for #{channel.slack_mention} is adaptive (decay=0.94)."
          )
        end

        it 'switches to standard at start of season' do
          expect(message: '@gamebot set elo algorithm standard', user: captain, channel: channel).to respond_with_slack_message(
            "Elo algorithm for #{channel.slack_mention} is standard (k=32)."
          )
          expect(channel.reload.elo_algorithm).to eq 'standard'
        end

        it 'errors when matches exist in current season' do
          Fabricate(:match, channel: channel)
          expect(message: '@gamebot set elo algorithm standard', user: captain, channel: channel).to respond_with_slack_message(
            'Elo algorithm can only be changed at the start of a new season.'
          )
          expect(channel.reload.elo_algorithm).to eq 'adaptive'
        end

        it 'errors on invalid algorithm' do
          expect(message: '@gamebot set elo algorithm invalid', user: captain, channel: channel).to respond_with_slack_message(
            'Invalid elo algorithm invalid, valid options are: adaptive, standard, glicko, glicko2.'
          )
        end

        it 'switches to glicko at start of season' do
          expect(message: '@gamebot set elo algorithm glicko', user: captain, channel: channel).to respond_with_slack_message(
            "Elo algorithm for #{channel.slack_mention} is glicko."
          )
          expect(channel.reload.elo_algorithm).to eq 'glicko'
        end

        it 'switches to glicko2 at start of season' do
          expect(message: '@gamebot set elo algorithm glicko2', user: captain, channel: channel).to respond_with_slack_message(
            "Elo algorithm for #{channel.slack_mention} is glicko2 (τ=0.5)."
          )
          expect(channel.reload.elo_algorithm).to eq 'glicko2'
        end

        it 'errors without captain' do
          non_captain = Fabricate(:user, channel: channel)
          expect(message: '@gamebot set elo algorithm standard', user: non_captain, channel: channel).to respond_with_slack_message(
            "You're not a captain, sorry."
          )
        end
      end

      context 'k' do
        before do
          channel.update_attributes!(elo_algorithm: 'standard')
        end

        it 'shows current k' do
          expect(message: '@gamebot set elo k', user: captain, channel: channel).to respond_with_slack_message(
            "Elo K for #{channel.slack_mention} is 32."
          )
        end

        it 'sets k' do
          expect(message: '@gamebot set elo k 16', user: captain, channel: channel).to respond_with_slack_message(
            "Elo K for #{channel.slack_mention} is 16."
          )
          expect(channel.reload.elo_k).to eq 16
        end

        it 'errors when algorithm is not standard' do
          channel.update_attributes!(elo_algorithm: 'adaptive')
          expect(message: '@gamebot set elo k 16', user: captain, channel: channel).to respond_with_slack_message(
            'K can only be set when the elo algorithm is standard.'
          )
        end

        it 'errors on invalid number' do
          expect(message: '@gamebot set elo k invalid', user: captain, channel: channel).to respond_with_slack_message(
            'Sorry, invalid is not a valid number.'
          )
        end
      end

      context 'decay' do
        it 'shows current decay' do
          expect(message: '@gamebot set elo decay', user: captain, channel: channel).to respond_with_slack_message(
            "Elo decay for #{channel.slack_mention} is 0.94."
          )
        end

        it 'sets decay' do
          expect(message: '@gamebot set elo decay 0.9', user: captain, channel: channel).to respond_with_slack_message(
            "Elo decay for #{channel.slack_mention} is 0.9."
          )
          expect(channel.reload.elo_decay).to eq 0.9
        end

        it 'errors when algorithm is not adaptive' do
          channel.update_attributes!(elo_algorithm: 'standard')
          expect(message: '@gamebot set elo decay 0.9', user: captain, channel: channel).to respond_with_slack_message(
            'Decay can only be set when the elo algorithm is adaptive.'
          )
        end

        it 'errors when decay is out of range' do
          expect(message: '@gamebot set elo decay 1.5', user: captain, channel: channel).to respond_with_slack_message(
            'Elo decay must be between 0 and 1.'
          )
        end

        it 'errors on invalid number' do
          expect(message: '@gamebot set elo decay invalid', user: captain, channel: channel).to respond_with_slack_message(
            'Sorry, invalid is not a valid number.'
          )
        end
      end

      context 'glicko2 tau' do
        before do
          channel.update_attributes!(elo_algorithm: 'glicko2')
        end

        it 'shows current tau' do
          expect(message: '@gamebot set elo glicko2 tau', user: captain, channel: channel).to respond_with_slack_message(
            "Glicko2 τ for #{channel.slack_mention} is 0.5."
          )
        end

        it 'sets tau' do
          expect(message: '@gamebot set elo glicko2 tau 0.3', user: captain, channel: channel).to respond_with_slack_message(
            "Glicko2 τ for #{channel.slack_mention} is 0.3."
          )
          expect(channel.reload.elo_glicko2_tau).to eq 0.3
        end

        it 'errors when algorithm is not glicko2' do
          channel.update_attributes!(elo_algorithm: 'adaptive')
          expect(message: '@gamebot set elo glicko2 tau 0.3', user: captain, channel: channel).to respond_with_slack_message(
            'Glicko2 τ can only be set when the elo algorithm is glicko2.'
          )
        end

        it 'errors when tau is not positive' do
          expect(message: '@gamebot set elo glicko2 tau 0', user: captain, channel: channel).to respond_with_slack_message(
            'Glicko2 τ must be positive.'
          )
        end

        it 'errors on invalid number' do
          expect(message: '@gamebot set elo glicko2 tau invalid', user: captain, channel: channel).to respond_with_slack_message(
            'Sorry, invalid is not a valid number.'
          )
        end
      end
    end

    context 'leaderboard max' do
      context 'with a non-default leaderboard max' do
        before do
          channel.update_attributes!(leaderboard_max: 5)
        end

        it 'shows current value of leaderboard max' do
          expect(message: '@gamebot set leaderboard max', user: captain, channel: channel).to respond_with_slack_message(
            "Leaderboard max for #{channel.slack_mention} is 5."
          )
        end

        it 'sets leaderboard max' do
          expect(message: '@gamebot set leaderboard max 12', user: captain, channel: channel).to respond_with_slack_message(
            "Leaderboard max for #{channel.slack_mention} is 12."
          )
          expect(channel.reload.leaderboard_max).to eq 12
        end

        it 'sets leaderboard max to a negative number' do
          expect(message: '@gamebot set leaderboard max -12', user: captain, channel: channel).to respond_with_slack_message(
            "Leaderboard max for #{channel.slack_mention} is -12."
          )
          expect(channel.reload.leaderboard_max).to eq(-12)
        end

        it 'handles errors' do
          expect(message: '@gamebot set leaderboard max invalid', user: captain, channel: channel).to respond_with_slack_message(
            'Sorry, invalid is not a valid number.'
          )
          expect(channel.reload.leaderboard_max).to eq 5
        end

        it 'resets leaderboard max with set 0' do
          expect(message: '@gamebot set leaderboard max 0', user: captain, channel: channel).to respond_with_slack_message(
            "Leaderboard max for #{channel.slack_mention} is not set."
          )
          expect(channel.reload.leaderboard_max).to be_nil
        end

        it 'resets leaderboard max with set infinity' do
          expect(message: '@gamebot set leaderboard max infinity', user: captain, channel: channel).to respond_with_slack_message(
            "Leaderboard max for #{channel.slack_mention} is not set."
          )
          expect(channel.reload.leaderboard_max).to be_nil
        end

        it 'resets leaderboard max with unset' do
          expect(message: '@gamebot unset leaderboard max', user: captain, channel: channel).to respond_with_slack_message(
            "Leaderboard max for #{channel.slack_mention} has been unset."
          )
          expect(channel.reload.leaderboard_max).to be_nil
        end
      end
    end

    context 'invalid' do
      it 'errors set' do
        expect(message: '@gamebot set invalid on', user: captain, channel: channel).to respond_with_slack_message(
          'Invalid setting invalid, you can _set gifs on|off_, _set unbalanced on|off_, _set won on|off_, _api on|off_, _leaderboard max_, _elo_, _nickname_, _aliases_ and _expire_.'
        )
      end

      it 'errors unset' do
        expect(message: '@gamebot unset invalid', user: captain, channel: channel).to respond_with_slack_message(
          'Invalid setting invalid, you can _unset gifs_, _unset won_, _api_, _leaderboard max_, _elo_, _nickname_, _aliases_ and _expire_.'
        )
      end
    end

    context 'expire' do
      it 'shows current value of expire' do
        expect(message: '@gamebot set expire', user: captain, channel: channel).to respond_with_slack_message(
          'Challenges expire after 8 hours.'
        )
      end

      it 'shows expire of 30 minutes' do
        channel.update_attributes!(expire: 30)
        expect(message: '@gamebot set expire', user: captain, channel: channel).to respond_with_slack_message(
          'Challenges expire after 30 minutes.'
        )
      end

      it 'shows expire of never' do
        channel.update_attributes!(expire: nil)
        expect(message: '@gamebot set expire', user: captain, channel: channel).to respond_with_slack_message(
          'Challenges never expire.'
        )
      end

      it 'sets expire in hours' do
        expect(message: '@gamebot set expire 2 hours', user: captain, channel: channel).to respond_with_slack_message(
          'Challenges expire after 2 hours.'
        )
        expect(channel.reload.expire).to eq 120
      end

      it 'sets expire in minutes' do
        expect(message: '@gamebot set expire 30 min', user: captain, channel: channel).to respond_with_slack_message(
          'Challenges expire after 30 minutes.'
        )
        expect(channel.reload.expire).to eq 30
      end

      it 'sets expire with a bare number (treated as minutes)' do
        expect(message: '@gamebot set expire 30', user: captain, channel: channel).to respond_with_slack_message(
          'Challenges expire after 30 minutes.'
        )
        expect(channel.reload.expire).to eq 30
      end

      it 'sets expire to never' do
        expect(message: '@gamebot set expire never', user: captain, channel: channel).to respond_with_slack_message(
          'Challenges never expire.'
        )
        expect(channel.reload.expire).to be_nil
      end

      it 'unsets expire to never' do
        expect(message: '@gamebot unset expire', user: captain, channel: channel).to respond_with_slack_message(
          'Challenges never expire.'
        )
        expect(channel.reload.expire).to be_nil
      end

      it 'errors on invalid duration' do
        expect(message: '@gamebot set expire banana', user: captain, channel: channel).to respond_with_slack_message(
          "Sorry, 'banana' is not a valid duration, e.g. _30 minutes_, _2 hours_ or _never_."
        )
      end

      it 'errors when duration is less than 15 minutes' do
        expect(message: '@gamebot set expire 10 min', user: captain, channel: channel).to respond_with_slack_message(
          'Expiry duration must be at least 15 minutes.'
        )
      end

      it 'cannot set expire without being a captain' do
        non_captain = Fabricate(:user, channel: channel)
        expect(message: '@gamebot set expire 2 hours', user: non_captain, channel: channel).to respond_with_slack_message(
          "You're not a captain, sorry."
        )
      end
    end
  end

  context 'not captain' do
    context 'without arguments' do
      it 'shows default settings' do
        expect(message: '@gamebot set', user: captain, channel: channel).to respond_with_slack_message([
          'API for channel <#channel> is on, and the team API token is not set.',
          'Bot aliases are not set.',
          'Challenges expire after 8 hours.',
          'GIFs are on.',
          'Elo is 0.',
          'Elo algorithm is adaptive (decay=0.94).',
          'Leaderboard max is not set.',
          'Unbalanced challenges are off by default.',
          'Won command is on.'
        ].join("\n"))
      end

      it 'errors on unset' do
        expect(message: '@gamebot unset', user: captain, channel: channel).to respond_with_slack_message(
          'Missing setting, you can _unset gifs_, _api_, _leaderboard max_, _elo_, _nickname_, _aliases_ and _expire_.'
        )
      end
    end

    context 'api' do
      it 'cannot set api' do
        expect(message: '@gamebot set api true', user: user, channel: channel).to respond_with_slack_message(
          "You're not a captain, sorry."
        )
      end

      it 'can see api' do
        expect(message: '@gamebot set api', user: user, channel: channel).to respond_with_slack_message(
          "API for #{channel.slack_mention} is on!\nDM the bot _set token_ to get or set an API token to pass as an `X-Access-Token` header to #{channel.api_url}."
        )
      end
    end

    context 'gifs' do
      it 'cannot set GIFs' do
        expect(message: '@gamebot set gifs true', user: user, channel: channel).to respond_with_slack_message(
          "You're not a captain, sorry."
        )
      end

      it 'can see GIFs value' do
        expect(message: '@gamebot set gifs', user: user, channel: channel).to respond_with_slack_message(
          "GIFs for #{channel.slack_mention} are on!"
        )
      end
    end

    context 'aliases' do
      it 'cannot set aliases' do
        expect(message: '@gamebot set aliases foo bar', user: user, channel: channel).to respond_with_slack_message(
          "You're not a captain, sorry."
        )
      end

      it 'can see aliases' do
        expect(message: '@gamebot set aliases', user: user, channel: channel).to respond_with_slack_message(
          "#{channel.slack_mention} does not have any bot aliases."
        )
      end
    end

    context 'elo' do
      it 'cannot set elo' do
        expect(message: '@gamebot set elo 1000', user: user, channel: channel).to respond_with_slack_message(
          "You're not a captain, sorry."
        )
      end

      it 'can see elo' do
        expect(message: '@gamebot set elo', user: user, channel: channel).to respond_with_slack_message(
          "Base elo for #{channel.slack_mention} is 0."
        )
      end
    end

    context 'details' do
      it 'cannot set details' do
        expect(message: '@gamebot set details leaderboard', user: user, channel: channel).to respond_with_slack_message(
          "You're not a captain, sorry."
        )
      end

      it 'can see details' do
        expect(message: '@gamebot set details', user: user, channel: channel).to respond_with_slack_message(
          "Match details for #{channel.slack_mention} are `elo`."
        )
      end
    end

    context 'leaderboard max' do
      it 'cannot set leaderboard max' do
        expect(message: '@gamebot set leaderboard max 3', user: user, channel: channel).to respond_with_slack_message(
          "You're not a captain, sorry."
        )
      end

      it 'can see leaderboard max' do
        expect(message: '@gamebot set leaderboard max', user: user, channel: channel).to respond_with_slack_message(
          "Leaderboard max for #{channel.slack_mention} is not set."
        )
      end
    end
  end

  context 'nickname' do
    let(:user) { Fabricate(:user, channel: channel, user_name: 'username') }

    context 'with no nickname' do
      it 'shows that the user has no nickname' do
        expect(message: '@gamebot set nickname', user: user, channel: channel).to respond_with_slack_message(
          "You don't have a nickname set, #{user.user_name}."
        )
      end
    end

    context 'without a nickname set' do
      it 'sets nickname' do
        expect(message: '@gamebot set nickname john doe', user: user, channel: channel).to respond_with_slack_message(
          "Your nickname is now _john doe_, #{user.slack_mention}."
        )
        expect(user.reload.nickname).to eq 'john doe'
      end

      it 'does not unset nickname' do
        expect(message: '@gamebot unset nickname', user: user, channel: channel).to respond_with_slack_message(
          "You don't have a nickname set, #{user.slack_mention}."
        )
        expect(user.reload.nickname).to be_nil
      end

      it 'sets emoji nickname' do
        expect(message: '@gamebot set nickname :dancer:', user: user, channel: channel).to respond_with_slack_message(
          "Your nickname is now _:dancer:_, #{user.slack_mention}."
        )
        expect(user.reload.nickname).to eq ':dancer:'
      end
    end

    context 'with a nickname set' do
      before do
        user.update_attributes!(nickname: 'bob')
      end

      it 'shows current value of nickname' do
        expect(message: '@gamebot set nickname', user: user, channel: channel).to respond_with_slack_message(
          "Your nickname is _bob_, #{user.slack_mention}."
        )
      end

      it 'sets nickname' do
        expect(message: '@gamebot set nickname john doe', user: user, channel: channel).to respond_with_slack_message(
          "Your nickname is now _john doe_, #{user.slack_mention}."
        )
        expect(user.reload.nickname).to eq 'john doe'
      end

      it 'unsets nickname' do
        expect(message: '@gamebot unset nickname', user: user, channel: channel).to respond_with_slack_message(
          "You don't have a nickname set anymore, #{user.slack_mention}."
        )
        expect(user.reload.nickname).to be_nil
      end

      it 'cannot set nickname unless captain' do
        expect(message: "@gamebot set nickname #{captain.slack_mention} :dancer:", user: user, channel: channel).to respond_with_slack_message(
          "You're not a captain, sorry."
        )
      end

      it 'sets nickname for another user' do
        captain = Fabricate(:user, channel: channel, captain: true)
        expect(message: "@gamebot set nickname #{user.slack_mention} john doe", user: captain, channel: channel).to respond_with_slack_message(
          "Your nickname is now _john doe_, #{user.slack_mention}."
        )
        expect(user.reload.nickname).to eq 'john doe'
      end

      it 'unsets nickname for another user' do
        user.update_attributes!(nickname: 'bob')
        expect(message: "@gamebot unset nickname #{user.slack_mention}", user: captain, channel: channel).to respond_with_slack_message(
          "You don't have a nickname set anymore, #{user.slack_mention}."
        )
        expect(user.reload.nickname).to be_nil
      end
    end
  end

  context 'in a private channel' do
    before do
      channel.update_attributes!(is_group: true)
      user.update_attributes!(captain: true)
    end

    context 'aliases' do
      it 'are not supported' do
        expect(message: '@gamebot set aliases', user: captain, channel: channel).to respond_with_slack_message(
          'Bot aliases are not supported in private channels, sorry.'
        )
      end
    end
  end
end
