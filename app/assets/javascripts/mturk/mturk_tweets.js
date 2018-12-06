// websocket update functions (see channels/job_notification.js)
// Running
function onRefreshAvailability() {
  $('#refresh-availability').bind('ajax:beforeSend', function() {
    $('#refresh-availability').hide()
    $('#refresh-availability-running').show()
  })
  $('#refresh-mturk-hits').on('ajax:error', function(e) {
    $('#refresh-availability').show()
    $('#refresh-availability-running').hide()
  })
}
// Completed
function onRefreshAvailabilityComplete() {
  // Reload will show new data
  if (window.location.pathname.endsWith('mturk_tweets')) {
    window.location.reload();
  }
}

$(document).on('turbolinks:load', function() {
  onRefreshAvailability();
})
// Running
function onMturkTweetsS3UploadRunning(mturk_batch_job_id) {
  if (window.location.pathname.endsWith('mturk_tweets')) {
    $(`#mturk-tweets-${mturk_batch_job_id}-spinner`).show()
    $(`#mturk-tweets-${mturk_batch_job_id}-icon`).hide()
    toastr.info('Preparing CSV. This may take a while...')
  }
}
// Completed
function onMturkTweetsS3UploadComplete(mturk_batch_job_id) {
  if (window.location.pathname.endsWith('mturk_tweets')) {
    $(`#mturk-tweets-${mturk_batch_job_id}-spinner`).hide()
    $(`#mturk-tweets-${mturk_batch_job_id}-icon`).show()
    toastr.clear()
    toastr.success('CSV is now ready to download!')
    window.location.reload()
  }
}
