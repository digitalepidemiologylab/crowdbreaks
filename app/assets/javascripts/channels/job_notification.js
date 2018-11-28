$(document).on("turbolinks:load", function() {
  // Check for meta tag in the header which should only be present when the user is loggedin.
  // If the user is not logged in, do not attempt at making a websocket connection
  if ($("meta[name='user-signed-in']").length > 0) {
    App.job_notification = App.cable.subscriptions.create("JobNotificationChannel", {
      connected: function() {
        // Called when the subscription is ready for use on the server
      },

      disconnected: function() {
        // Called when the subscription has been terminated by the server
      },

      received: function(data) {
        // Called when there's incoming data on the websocket for this channel
        if (data['job_type'] = 'update_mturk_hits') {
          if (data['job_status'] == 'completed') {
            onUpdateMturkHitsComplete(data['message']);
          } else if (data['job_status'] == 'running') {
            onUpdateMturkHitsRunning(data['hits_loaded']);
          } else if (data['job_status'] == 'failed') {
            onUpdateMturkHitsFailed();
          }
        }
        if (data['job_type'] = 'refresh_mturk_tweets') {
          if (data['job_status'] == 'completed') {
            onRefreshAvailabilityComplete();
          }
        }
        if (data['job_type'] = 'mturk_batch_job_s3_upload') {
          if (data['job_status'] == 'running') {
            onMturkBatchJobS3UploadRunning(data['mturk_batch_job_id']);
          } else if (data['job_status'] == 'completed') {
            onMturkBatchJobS3UploadComplete(data['mturk_batch_job_id']);
          }
        }
      }
    });
  }
})
