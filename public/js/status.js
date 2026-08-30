$(document).ready(function() {

  // Legacy stats from www.playplay.io (the site was migrated to gamebot2.playplay.io,
  // which reset local counters) are added in so real historical totals are shown.
  // The tagline starts hidden (see index.html.erb) and is only revealed once, with a
  // fade-in, either with the combined live stats (if both requests succeed) or with
  // the static default text (on failure), so users never see it change/flash from one to the other.
  var $tagline = $('#active_teams_count');

  $.when(
    $.ajax({ type: "GET", url: "https://www.playplay.io/api/status" }),
    $.ajax({ type: "GET", url: "/api/status" })
  ).done(function(legacyResponse, currentResponse) {
    var legacy = legacyResponse[0];
    var current = currentResponse[0];
    var legacyMatchesCount = 0;
    var legacyUsersCount = 0;

    $.each(legacy.games || {}, function(_, game) {
      legacyMatchesCount += game.matches_count || 0;
      legacyUsersCount += game.users_count || 0;
    });

    $tagline.text(
      "The leaderboard bot for startup ping pong since 2016, with " +
      (current.matches_count + legacyMatchesCount) + " games recorded by " +
      (current.users_count + legacyUsersCount) + " players."
    );
  }).always(function() {
    $tagline.fadeIn('slow');
  });

});
