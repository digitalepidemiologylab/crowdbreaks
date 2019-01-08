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
        switch(data['job_type']) {
          case 'update_mturk_hits':
            switch(data['job_status']) {
              case 'running':
                onUpdateMturkHitsRunning(data['hits_loaded']);
                break;
              case 'completed':
                onUpdateMturkHitsComplete(data['message']);
                break;
              case 'failed':
                onUpdateMturkHitsFailed();
                break;
            }
            break;
          case 'refresh_mturk_tweets':
            if (data['job_status'] == 'completed') {
              onRefreshAvailabilityComplete();
            }
            break;
          case 'mturk_batch_job_s3_upload':
            switch(data['job_status']) {
              case 'running':
                onMturkBatchJobS3UploadRunning(data['mturk_batch_job_id']);
                break;
              case 'completed':
                onMturkBatchJobS3UploadComplete(data['mturk_batch_job_id']);
                break;
            }
            break;
          case 'mturk_tweets_s3_upload':
            switch(data['job_status']) {
              case 'running':
                onMturkTweetsS3UploadRunning(data['mturk_batch_job_id']);
                break;
              case 'completed':
                onMturkTweetsS3UploadComplete(data['mturk_batch_job_id']);
                break;
            }
            break;
          case 'mturk_worker_refresh_review_status':
            if (data['job_status'] == 'completed') {
              onRefreshReviewStatusComplete(data['assignment']);
            }
            break;
        }
      }
    });
  }
})
