# frozen_string_literal: true

require 'spec_helper'

describe SlackGamebot::Commands::SetTeam do
  include_context 'dm'

  let(:admin) { Fabricate(:admin, is_owner: true, is_admin: true) }
  let(:user) { Fabricate(:admin, is_owner: false, is_admin: false, user_id: 'some_user_id') }

  context 'without arguments' do
    it 'shows default settings' do
      expect(message: '@gamebot set', user: user.user_id, channel: 'DM').to respond_with_slack_message([
        "API for team #{user.team.team_id} is on, and the API token is not set.",
        'Default bot aliases are `gamebot`, `pongbot` and `pp`.',
        'GIFs are on by default.',
        'Default elo is 0.',
        'Default leaderboard max is not set.',
        'Unbalanced challenges are off by default.'
      ].join("\n"))
    end

    it 'errors on unset' do
      expect(message: '@gamebot unset', user: user.user_id, channel: 'DM').to respond_with_slack_message(
        'Missing setting, you can _unset gifs_, _unbalanced_, _api_, _token_, _leaderboard max_, _elo_ and _aliases_.'
      )
    end
  end

  context 'invalid' do
    it 'errors set' do
      expect(message: '@gamebot set invalid on', user: user.user_id, channel: 'DM').to respond_with_slack_message(
        'Invalid setting invalid, you can _set gifs on|off_, _set unbalanced on|off_, _api on|off_, _set token xyz_, _leaderboard max_, _elo_ and _aliases_.'
      )
    end

    it 'errors unset' do
      expect(message: '@gamebot unset invalid', user: user.user_id, channel: 'DM').to respond_with_slack_message(
        'Invalid setting invalid, you can _unset gifs_, _unbalanced_, _api_, _token_, _leaderboard max_, _elo_ and _aliases_.'
      )
    end
  end

  context 'not admin' do
    context 'api' do
      it 'cannot set api' do
        expect(message: '@gamebot set api true', user: user.user_id, channel: 'DM').to respond_with_slack_message(
          "You're not a team admin, sorry."
        )
      end

      it 'can see api' do
        expect(message: '@gamebot set api', user: user.user_id, channel: 'DM').to respond_with_slack_message(
          "API for team #{team.team_id} is on, set an API token with _set token xyz_."
        )
      end
    end

    context 'token' do
      it 'cannot set token' do
        expect(message: '@gamebot set token xyz', user: user.user_id, channel: 'DM').to respond_with_slack_message(
          "You're not a team admin, sorry."
        )
      end

      it 'cannot see api token' do
        expect(message: '@gamebot set token', user: user.user_id, channel: 'DM').to respond_with_slack_message(
          "You're not a team admin, sorry."
        )
      end
    end

    context 'gifs' do
      it 'cannot set GIFs' do
        expect(message: '@gamebot set gifs true', user: user.user_id, channel: 'DM').to respond_with_slack_message(
          "You're not a team admin, sorry."
        )
      end

      it 'can see GIFs value' do
        expect(message: '@gamebot set gifs', user: user.user_id, channel: 'DM').to respond_with_slack_message(
          'GIFs are on by default!'
        )
      end
    end

    context 'aliases' do
      it 'cannot set aliases' do
        expect(message: '@gamebot set aliases foo bar', user: user.user_id, channel: 'DM').to respond_with_slack_message(
          "You're not a team admin, sorry."
        )
      end

      it 'can see aliases' do
        expect(message: '@gamebot set aliases', user: user.user_id, channel: 'DM').to respond_with_slack_message(
          'Default bot aliases are `gamebot`, `pongbot` and `pp`.'
        )
      end
    end

    context 'elo' do
      it 'cannot set elo' do
        expect(message: '@gamebot set elo 1000', user: user.user_id, channel: 'DM').to respond_with_slack_message(
          "You're not a team admin, sorry."
        )
      end

      it 'can see elo' do
        expect(message: '@gamebot set elo', user: user.user_id, channel: 'DM').to respond_with_slack_message(
          'Default base elo is 0.'
        )
      end
    end

    context 'leaderboard max' do
      it 'cannot set leaderboard max' do
        expect(message: '@gamebot set leaderboard max 3', user: user.user_id, channel: 'DM').to respond_with_slack_message(
          "You're not a team admin, sorry."
        )
      end

      it 'can see leaderboard max' do
        expect(message: '@gamebot set leaderboard max', user: user.user_id, channel: 'DM').to respond_with_slack_message(
          'Default leaderboard max is not set.'
        )
      end
    end
  end

  context 'admin' do
    context 'api' do
      it 'shows current value of API on' do
        team.update_attributes!(api: true)
        expect(message: '@gamebot set api', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          "API for team #{team.team_id} is on, set an API token with _set token xyz_."
        )
      end

      it 'shows current value of API on with token' do
        team.update_attributes!(api: true, api_token: 'token')
        expect(message: '@gamebot set api', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          "API for team #{team.team_id} is on, and the API token is set to `token`.\nPass it in with an `X-Access-Token` header to #{team.api_url}."
        )
      end

      it 'shows current value of API off' do
        team.update_attributes!(api: false)
        expect(message: '@gamebot set api', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          "API for team #{team.team_id} is off."
        )
      end

      it 'enables API' do
        expect(message: '@gamebot set api on', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          "API for team #{team.team_id} is now on, set an API token with _set token xyz_."
        )
        expect(team.reload.api).to be true
      end

      it 'disables API with set' do
        team.update_attributes!(api: true)
        expect(message: '@gamebot set api off', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          "API for team #{team.team_id} is now off."
        )
        expect(team.reload.api).to be false
      end

      it 'disables API with unset' do
        team.update_attributes!(api: true)
        expect(message: '@gamebot unset api', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          "API for team #{team.team_id} is now off."
        )
        expect(team.reload.api).to be false
      end
    end

    context 'token' do
      it 'shows current value of API token' do
        team.update_attributes!(api: true, api_token: 'token')
        expect(message: '@gamebot set token', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          "API for team #{team.team_id} is on, and the API token is `#{team.api_token}`.\nPass it in with an `X-Access-Token` header to #{team.api_url}."
        )
      end

      it 'shows when API token is not set' do
        team.update_attributes!(api: true, api_token: nil)
        expect(message: '@gamebot set token', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          "API for team #{team.team_id} is on, set an API token with _set token xyz_."
        )
      end

      it 'sets API token with set' do
        expect(message: '@gamebot set token xyz', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          "API for team #{team.team_id} is on, and the API token is now `xyz`.\nPass it in with an `X-Access-Token` header to #{team.api_url}."
        )
        expect(team.reload.api_token).to eq 'xyz'
      end

      it 'removes API token with unset' do
        team.update_attributes!(api_token: 'xyz')
        expect(message: '@gamebot unset token', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          "API token for team #{team.team_id} has been unset."
        )
        expect(team.reload.api_token).to be_nil
      end
    end

    context 'gifs' do
      it 'shows current value of GIFs on' do
        expect(message: '@gamebot set gifs', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          'GIFs are on by default!'
        )
      end

      it 'shows current value of GIFs off' do
        team.update_attributes!(gifs: false)
        expect(message: '@gamebot set gifs', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          'GIFs are off by default.'
        )
      end

      it 'enables GIFs' do
        team.update_attributes!(gifs: false)
        expect(message: '@gamebot set gifs on', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          'GIFs are on by default!'
        )
        expect(team.reload.gifs).to be true
      end

      it 'disables GIFs with set' do
        team.update_attributes!(gifs: true)
        expect(message: '@gamebot set gifs off', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          'GIFs are off by default.'
        )
        expect(team.reload.gifs).to be false
      end

      it 'disables GIFs with unset' do
        team.update_attributes!(gifs: true)
        expect(message: '@gamebot unset gifs', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          'GIFs are off by default.'
        )
        expect(team.reload.gifs).to be false
      end
    end

    context 'unbalanced' do
      it 'shows current value of unbalanced off' do
        team.update_attributes!(unbalanced: false)
        expect(message: '@gamebot set unbalanced', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          'Unbalanced challenges are off by default.'
        )
      end

      it 'enables unbalanced' do
        team.update_attributes!(unbalanced: false)
        expect(message: '@gamebot set unbalanced on', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          'Unbalanced challenges are on by default!'
        )
        expect(team.reload.unbalanced).to be true
      end

      it 'disables unbalanced with set' do
        team.update_attributes!(unbalanced: true)
        expect(message: '@gamebot set unbalanced off', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          'Unbalanced challenges are off by default.'
        )
        expect(team.reload.unbalanced).to be false
      end

      it 'disables unbalanced with unset' do
        team.update_attributes!(unbalanced: true)
        expect(message: '@gamebot unset unbalanced', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          'Unbalanced challenges are off by default.'
        )
        expect(team.reload.unbalanced).to be false
      end
    end

    context 'aliases' do
      context 'with aliases' do
        before do
          team.update_attributes!(aliases: %w[foo bar])
        end

        it 'shows current value of aliases' do
          expect(message: '@gamebot set aliases', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
            'Default bot aliases are `foo` and `bar`.'
          )
        end

        it 'sets aliases' do
          expect(message: '@gamebot set aliases foo bar baz', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
            'Default bot aliases are now `foo`, `bar` and `baz`.'
          )
          expect(team.reload.aliases).to eq %w[foo bar baz]
        end

        it 'sets comma-separated aliases' do
          expect(message: '@gamebot set aliases foo,bar', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
            'Default bot aliases are now `foo` and `bar`.'
          )
          expect(team.reload.aliases).to eq %w[foo bar]
        end

        it 'sets comma-separated aliases with extra spaces' do
          expect(message: '@gamebot set aliases   foo,    bar', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
            'Default bot aliases are now `foo` and `bar`.'
          )
          expect(team.reload.aliases).to eq %w[foo bar]
        end

        it 'sets emoji aliases' do
          expect(message: '@gamebot set aliases pp :pong:', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
            'Default bot aliases are now `pp` and `:pong:`.'
          )
          expect(team.reload.aliases).to eq ['pp', ':pong:']
        end

        it 'removes aliases' do
          expect(message: '@gamebot unset aliases', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
            'Default bot aliases unset.'
          )
          expect(team.reload.aliases).to be_empty
        end
      end

      context 'without aliases' do
        before do
          team.update_attributes!(aliases: [])
        end

        it 'shows no aliases' do
          expect(message: '@gamebot set aliases', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
            'No default bot aliases set.'
          )
        end
      end
    end

    context 'elo' do
      context 'with a non-default base elo' do
        before do
          team.update_attributes!(elo: 1000)
        end

        it 'shows current value of elo' do
          expect(message: '@gamebot set elo', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
            'Default base elo is 1000.'
          )
        end

        it 'sets elo' do
          expect(message: '@gamebot set elo 200', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
            'Default base elo is now 200.'
          )
          expect(team.reload.elo).to eq 200
        end

        it 'handles errors' do
          expect(message: '@gamebot set elo invalid', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
            'Sorry, invalid is not a valid number.'
          )
          expect(team.reload.elo).to eq 1000
        end

        it 'resets elo with set' do
          expect(message: '@gamebot set elo 0', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
            'Default base elo is now 0.'
          )
          expect(team.reload.elo).to eq 0
        end

        it 'resets elo with unset' do
          expect(message: '@gamebot unset elo', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
            'Default base elo has been unset.'
          )
          expect(team.reload.elo).to eq 0
        end
      end
    end

    context 'leaderboard max' do
      context 'with a non-default leaderboard max' do
        before do
          team.update_attributes!(leaderboard_max: 5)
        end

        it 'shows current value of leaderboard max' do
          expect(message: '@gamebot set leaderboard max', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
            'Default leaderboard max is 5.'
          )
        end

        it 'sets leaderboard max' do
          expect(message: '@gamebot set leaderboard max 12', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
            'Default leaderboard max is now 12.'
          )
          expect(team.reload.leaderboard_max).to eq 12
        end

        it 'sets leaderboard max to a negative number' do
          expect(message: '@gamebot set leaderboard max -12', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
            'Default leaderboard max is now -12.'
          )
          expect(team.reload.leaderboard_max).to eq(-12)
        end

        it 'handles errors' do
          expect(message: '@gamebot set leaderboard max invalid', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
            'Sorry, invalid is not a valid number.'
          )
          expect(team.reload.leaderboard_max).to eq 5
        end

        it 'resets leaderboard max with set 0' do
          expect(message: '@gamebot set leaderboard max 0', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
            'Default leaderboard max is now not set.'
          )
          expect(team.reload.leaderboard_max).to be_nil
        end

        it 'resets leaderboard max with set infinity' do
          expect(message: '@gamebot set leaderboard max infinity', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
            'Default leaderboard max is not set.'
          )
          expect(team.reload.leaderboard_max).to be_nil
        end

        it 'resets leaderboard max with unset' do
          expect(message: '@gamebot unset leaderboard max', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
            'Default leaderboard max has been unset.'
          )
          expect(team.reload.leaderboard_max).to be_nil
        end
      end
    end

    context 'invalid' do
      it 'errors set' do
        expect(message: '@gamebot set invalid on', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          'Invalid setting invalid, you can _set gifs on|off_, _set unbalanced on|off_, _api on|off_, _set token xyz_, _leaderboard max_, _elo_ and _aliases_.'
        )
      end

      it 'errors unset' do
        expect(message: '@gamebot unset invalid', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          'Invalid setting invalid, you can _unset gifs_, _unbalanced_, _api_, _token_, _leaderboard max_, _elo_ and _aliases_.'
        )
      end
    end
  end
end
