$(document).ready(function() {

  $.ajax({
    type: "GET",
    url: "/api/status",
    success: function(data) {
      $('#active_teams_count').hide().text(
        data.active_teams_count + " active teams with " + data.matches_count + ' games played by ' + data.users_count + " players!"
      ).fadeIn('slow');
    },
  });

});
