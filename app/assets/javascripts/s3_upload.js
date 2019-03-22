// websocket update functions (see channels/job_notification.js)
// Running
function onS3UploadRunning(type, record_id) {
  $(`#${type}-${record_id}-spinner`).show()
  $(`#${type}-${record_id}-icon`).hide()
  toastr.info('Preparing CSV. This may take a while...')
}
// Completed
function onS3UploadComplete(type, record_id) {
  $(`#${type}-${record_id}-spinner`).hide()
  $(`#${type}-${record_id}-icon`).show()
  toastr.clear()
  toastr.success('CSV is now ready to download!')
  window.location.reload()
}
// Failed
function onS3UploadFailed(type, record_id) {
  $(`#${type}-${record_id}-spinner`).hide()
  $(`#${type}-${record_id}-icon`).show()
  toastr.clear()
  toastr.error('CSV upload to S3 failed.')
  window.location.reload()
}
