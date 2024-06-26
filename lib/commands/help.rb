module SlackGamebot
  module Commands
    class Help < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      HELP = <<~EOS.freeze
        I am your friendly Gamebot, here to help.

        ```
        General
        -------
        hi: be nice, say hi to your bot
        team: show your team's info and captains
        register: re-register yourself as a player
        unregister: unregister yourself, removes you from leaderboards and challenges
        help: get this helpful message
        info: bot credits
        sucks: express some frustration

        Games
        -----
        challenge <opponent> ... [with <teammate> ...]: challenge opponent(s) to a game
        challenge @here|@channel: challenge anyone to a game
        challenge? <opponent> ... [with <teammate> ...]: show elo at stake
        accept: accept a challenge
        decline: decline a previous challenge
        cancel: cancel a previous challenge
        lost [to <opponent>] [score, ...]: record your loss
        resigned [to <opponent>]: record a resignation
        draw [to <opponent>] [score, ...]: record a tie
        taunt <opponent> [<opponent> ...]: taunt players
        rank [<player> ...]: rank a player or a list of players
        matches [number|infinity]: show this season's matches

        Stats
        -----
        leaderboard [number|infinity]: show the leaderboard, e.g. leaderboard 10
        season: show current season

        Settings
        --------
        set nickname [name], unset nickname: set/unset your nickname displayed in leaderboards
        set leaderboard max [number|infinity], unset leaderboard max: set/unset leaderboard max
        set gifs [on|off]: enable/disable animated GIFs, default is on
        set aliases [<alias> ...], unset aliases: set/unset additional bot aliases
        set elo [number]: set base elo for the team
        set api [on|off]: enable/disable team data in the public API, default is off
        set unbalanced [on|off]: allow matches between different numbers of players, default is off

        Captains
        --------
        promote <player>: promote a user to captain
        demote me: demote you from captain
        set nickname <player> [name], unset nickname <player>: set/unset someone's nickname
        seasons: show all seasons
        reset <channel>: reset all stats, start a new season
        unregister <player>: remove a player from the leaderboard
        subscription: show subscription info (captains also see payment data)
        unsubscribe: do not auto-renew subscription
        ```
      EOS

      user_command 'help' do |channel, _user, data|
        team = data.team
        (channel || team).slack_client.say(channel: data.channel, text: [
          HELP,
          team.reload.subscribed? ? nil : team.trial_message
        ].compact.join("\n"), gif: 'help')
        logger.info "HELP: #{team} - #{data.user}"
      end
    end
  end
end
