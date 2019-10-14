import consumer from "./consumer";
import {
  MturkCachedHitsJobNotificationHelpers,
  MturkTweetsJobNotificationHelpers,
  S3UploadHelpers
} from './job_notification_helpers';

$(document).on("turbolinks:load", function() {
  // Check for meta tag in the header which should only be present when the user is loggedin.
  // If the user is not logged in, do not attempt at making a websocket connection
  if ($("meta[name='user-signed-in']").length > 0) {
    consumer.subscriptions.create({ channel: "JobNotificationChannel" }, {
      connected: function() {
        // Called when the subscription is ready for use on the server
      },

      disconnected: function() {
        // Called when the subscription has been terminated by the server
      },

      received: function(data) {
        if (data['job_type'].endsWith('_s3_upload')) {
          data['job_type'] = data['job_type'].split('_s3_upload')[0]
          handle_s3_upload(data);
          return
        }
        // Called when there's incoming data on the websocket for this channel
        switch(data['job_type']) {
          case 'update_mturk_hits':
            switch(data['job_status']) {
              case 'running':
                MturkCachedHitsJobNotificationHelpers.running(data['hits_loaded']);
                break;
              case 'completed':
                MturkCachedHitsJobNotificationHelpers.complete(data['message']);
                break;
              case 'failed':
                MturkCachedHitsJobNotificationHelpers.failed();
                break;
            }
            break;
          case 'refresh_mturk_tweets':
            if (data['job_status'] == 'completed') {
              MturkTweetsJobNotificationHelpers.complete()
            }
            break;
          case 'mturk_worker_refresh_review_status':
            if (data['job_status'] == 'completed') {
              // to be implemented
            }
            break;
          case 'progress':
            onUpdateProgress(data['record_id'], data['record_type'], data['progress']);
            break;
        }
      }
    });
  }
})

function onUpdateProgress(record_id, record_type, progress) {
  // Hide context, show progress circle if not complete
  let progressCircleId = '#progress-circle-record-' + record_id + '-' + record_type;
  let progressCircleContextId = progressCircleId + '-context';
  if (progress < 100) {
    $(progressCircleContextId).hide();
    $(progressCircleId).show();
  } else {
    $(progressCircleContextId).show();
    $(progressCircleId).hide();
    return
  }
  // update progress if progress was made
  if (progress > $(progressCircleId).data('progress')) {
    $(progressCircleId).attr('data-progress', progress);
  }
}

function handle_s3_upload(data) {
  // Handling in app/assets/javascripts/s3_upload.js
  switch(data['job_status']) {
    case 'running':
      S3UploadHelpers.running(data['job_type'], data['record_id']);
      break;
    case 'completed':
      S3UploadHelpers.complete(data['job_type'], data['record_id']);
      break;
    case 'failed':
      S3UploadHelpers.failed(data['job_type'], data['record_id']);
      break;
  }
}
