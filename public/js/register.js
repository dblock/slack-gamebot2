$(document).ready(function() {
  // Slack OAuth
  var code = $.url('?code')
  if (code) {
    PlayPlay.register();
    PlayPlay.message('Working, please wait ...');
    $.ajax({
      type: "POST",
      url: "/api/teams",
      data: {
        code: code
      },
      success: function(data) {
        PlayPlay.message('Team successfully registered!<br>Invite the bot to a channel and follow its lead.');
      },
      error: PlayPlay.error
    });
  }
});
