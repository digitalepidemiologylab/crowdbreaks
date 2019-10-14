class MturkCachedHitsJobNotificationHelpers {
  static init() {
    $('#refresh-mturk-hits').bind('ajax:beforeSend', function() {
      $('#refresh-mturk-hits-group').hide()
      $('#refresh-mturk-hits-group-running').show()
      const text = 'Refreshing Mturk HITs. This may take a while...'
      setSpinnerInfoText(text, false);
    })
    $('#refresh-mturk-hits').on('ajax:error', function() {
      const text = 'Refreshing Mturk HITs failed.';
      setSpinnerInfoText(text, true);
    })
  }
  static running(hits_loaded) {
    const text = 'Refreshing Mturk HITs. This may take a while... (loaded ' + hits_loaded + ' HITs)';
    setSpinnerInfoText(text, false);
  }
  static failed() {
    const text = 'Refreshing Mturk HITs is already running. Try again later.';
    setSpinnerInfoText(text, true);
  }
  static complete(message) {
    setSpinnerInfoText(message, true);
    // Reload will show new data
    if (window.location.pathname.endsWith('mturk_hits')) {
      window.location.reload();
    }
  }
}


class MturkTweetsJobNotificationHelpers {
  static init() {
    $('#refresh-availability').bind('ajax:beforeSend', function() {
      $('#refresh-availability').hide()
      $('#refresh-availability-running').show()
    })
    $('#refresh-mturk-hits').on('ajax:error', function() {
      $('#refresh-availability').show()
      $('#refresh-availability-running').hide()
    })
  }
  static running(hits_loaded) {
    if (window.location.pathname.endsWith('mturk_tweets')) {
      $(`#mturk-tweets-${mturk_batch_job_id}-spinner`).show()
      $(`#mturk-tweets-${mturk_batch_job_id}-icon`).hide()
      toastr.info('Preparing CSV. This may take a while...')
    }
  }
  static complete(message) {
    if (window.location.pathname.endsWith('mturk_tweets')) {
      $(`#mturk-tweets-${mturk_batch_job_id}-spinner`).hide()
      $(`#mturk-tweets-${mturk_batch_job_id}-icon`).show()
      toastr.clear()
      toastr.success('CSV is now ready to download!')
      window.location.reload()
    }
  }
}

class S3UploadHelpers {
  static running(type, record_id) {
    $(`#${type}-${record_id}-spinner`).show()
    $(`#${type}-${record_id}-icon`).hide()
    toastr.info('Preparing CSV. This may take a while...')
  }
  static complete(type, record_id) {
    $(`#${type}-${record_id}-spinner`).hide()
    $(`#${type}-${record_id}-icon`).show()
    toastr.clear()
    toastr.success('CSV is now ready to download!')
    window.location.reload()
  }
  static failed(type, record_id) {
    $(`#${type}-${record_id}-spinner`).hide()
    $(`#${type}-${record_id}-icon`).show()
    toastr.clear()
    toastr.error('CSV upload to S3 failed.')
    window.location.reload()
  }
}

// helper
function setSpinnerInfoText(text, hideSpinner) {
  $('#refresh-mturk-hits-spinner-info').text(text);
  if (hideSpinner) {
    $('#refresh-mturk-hits-spinner').hide()
    $('#refresh-mturk-hits-spinner-info').css('position', 'relative');
  }
}

// call init functions
$(document).on('turbolinks:load', function() {
  MturkCachedHitsJobNotificationHelpers.init();
  MturkTweetsJobNotificationHelpers.init();
})

export {
  MturkCachedHitsJobNotificationHelpers,
  MturkTweetsJobNotificationHelpers,
  S3UploadHelpers
};
