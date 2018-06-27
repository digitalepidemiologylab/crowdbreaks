function toggleTwitterOptions() {
  // toggle checkbox to hide options
  $('#twitter-streaming-options-checkbox').change(function() {
    if (this.checked) {
      $('#twitter-streaming-options').show()
    } else {
      $('#twitter-streaming-options').hide()
    }
  })
}

$(document).on('turbolinks:load', function() {
  toggleTwitterOptions();
  // show/hide options based on configuration
  if ($('#twitter-streaming-options').data('active-stream')) {
    $('#twitter-streaming-options').show();
  } else {
    $('#twitter-streaming-options').hide();
  }
})
