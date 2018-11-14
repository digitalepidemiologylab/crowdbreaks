// Sart running
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
