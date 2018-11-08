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
  $('.production-checkbox').change(function() {
    let toBeChecked = $(this).is(':checked');
    toggleParam('sandbox', !toBeChecked);
  });
}
function toggleFiltered() {
  $('.filtered-checkbox').change(function() {
    let toBeChecked = $(this).is(':checked');
    toggleParam('filtered', toBeChecked);
  });
}
function toggleReviewable() {
  $('.reviewable-checkbox').change(function() {
    let toBeChecked = $(this).is(':checked');
    toggleParam('reviewable', toBeChecked);
  });
}
function toggleIncludeReviewed() {
  $('.include-reviewed-checkbox').change(function() {
    let toBeChecked = $(this).is(':checked');
    toggleParam('include_reviewed', toBeChecked);
  });
}

function toggleParam(param, toBeChecked) {
  var url = new URL(window.location.href);
  url.searchParams.delete(param)
  if (toBeChecked) {
    url.searchParams.append(param, true)
  } else {
    url.searchParams.append(param, false)
  }
  window.location.href = url.href
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
  toggleReviewable();
  onRefreshMturkHits();
  toggleIncludeReviewed();
})
