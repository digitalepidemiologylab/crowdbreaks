function toggleTwitterOptions() {
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
  $('#twitter-streaming-options').hide()
})
