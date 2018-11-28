function convertUnitsBeforeSubmit() {
  $('#mturk-batch-job-form').submit(function(e) {
    // convert days -> s
    $('input#mturk_batch_job_lifetime_in_seconds')[0].value *= 24*3600;
    $('input#mturk_batch_job_auto_approval_delay_in_seconds')[0].value *= 24*3600;
    // convert min -> s
    $('input#mturk_batch_job_assignment_duration_in_seconds')[0].value *= 60;
    return true;
  });
}

// websocket update functions (see channels/job_notification.js)
// Running
function onMturkBatchJobS3UploadRunning(mturk_batch_job_id) {
  if (window.location.pathname.endsWith('mturk_batch_jobs')) {
    $(`#mturk-batch-job-${mturk_batch_job_id}-spinner`).show()
    $(`#mturk-batch-job-${mturk_batch_job_id}-icon`).hide()
    toastr.info('Preparing CSV. This may take a while...')
  }
}
// Completed
function onMturkBatchJobS3UploadComplete(mturk_batch_job_id) {
  if (window.location.pathname.endsWith('mturk_batch_jobs')) {
    $(`#mturk-batch-job-${mturk_batch_job_id}-spinner`).hide()
    $(`#mturk-batch-job-${mturk_batch_job_id}-icon`).show()
    toastr.clear()
    toastr.success('CSV is now ready to download!')
    window.location.reload()
  }
}

$(document).on('turbolinks:load', function() {
  convertUnitsBeforeSubmit();
})
