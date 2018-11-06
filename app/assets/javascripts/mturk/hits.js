// websocket update functions (see channels/job_notification.js)
// Running
function onUpdateMturkHitsRunning(hits_loaded) {
  var text = 'Refreshing Mturk HITs. This may take a while... (loaded ' + hits_loaded + ' HITs)';
  setSpinnerInfoText(text, false);
}
// Failed
function onUpdateMturkHitsFailed(hits_loaded) {
  var text = 'Refreshing Mturk HITs is already running. Try again later.';
  setSpinnerInfoText(text, true);
}

// Completed
function onUpdateMturkHitsComplete(message) {
  setSpinnerInfoText(message, true);
  // Reload will show new data
  if (window.location.pathname.endsWith('mturk_hits')) {
    window.location.reload();
  }
}

// Start Update cached hits
function onRefreshMturkHits() {
  $('#refresh-mturk-hits').bind('ajax:beforeSend', function() {
    $('#refresh-mturk-hits-group').hide()
    $('#refresh-mturk-hits-group-running').show()
    var text = 'Refreshing Mturk HITs. This may take a while...'
    setSpinnerInfoText(text, false);
  })
  $('#refresh-mturk-hits').on('ajax:error', function(e) {
    var text = 'Refreshing Mturk HITs failed.';
    setSpinnerInfoText(text, true);
  })
}

// Toggle switches
function toggleSandbox() {
  $('#production-checkbox').change(function() {
    var url = new URL(window.location.href);
    url.searchParams.delete('page')
    url.searchParams.delete('next_token')
    url.searchParams.delete('sandbox')
    if($(this).is(':checked')) {
      url.searchParams.append('sandbox', false)
    } else {
      url.searchParams.append('sandbox', true)
    }
    window.location.href = url.href
  });
}

function toggleFiltered() {
  $('#filtered-checkbox').change(function() {
    var url = new URL(window.location.href);
    url.searchParams.delete('page')
    url.searchParams.delete('next_token')
    url.searchParams.delete('filtered')
    if($(this).is(':checked')) {
      url.searchParams.append('filtered', true)
    } else {
      url.searchParams.append('filtered', false)
    }
    window.location.href = url.href
  });
}

// helper
function setSpinnerInfoText(text, hideSpinner) {
  $('#refresh-mturk-hits-spinner-info').text(text);
  if (hideSpinner) {
    $('#refresh-mturk-hits-spinner').hide()
    $('#refresh-mturk-hits-spinner-info').css('position', 'relative');
  }
}

$(document).on('turbolinks:load', function() {
  toggleSandbox();
  toggleFiltered();
  onRefreshMturkHits();
})
