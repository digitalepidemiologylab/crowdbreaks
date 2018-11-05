$(document).on("turbolinks:load", function() {
  // Check for meta tag in the header which should only be present when the user is loggedin.
  // If the user is not logged in, do not attempt at making a websocket connection
  if ($("meta[name='user-signed-in']").length > 0) {
    App.job_notification = App.cable.subscriptions.create("JobNotificationChannel", {
      connected: function() {
        console.log('connected')
        // Called when the subscription is ready for use on the server
      },

      disconnected: function() {
        console.log('disconnected')
        // Called when the subscription has been terminated by the server
      },

      received: function(data) {
        // Called when there's incoming data on the websocket for this channel
        console.log('received data')
        if (data['job_type'] = 'update_mturk_hits') {
          onUpdateMturkHitsComplete();
        }
      }
    });
  }
})
