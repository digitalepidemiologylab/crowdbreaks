function toggleTwitterOptions() {
  // toggle checkbox to hide options
  $('.twitter-streaming-options-checkbox').change(function() {
    if (this.checked) {
      $('#twitter-streaming-options').show()
    } else {
      $('#twitter-streaming-options').hide()
    }
  })
}

function annotationModeSelect() {
  $('#select-annotation-mode').change(function() {
    if ($('#select-annotation-mode').val() == 0) {
      $('#options-annotation-mode-local').hide()
    } else {
      $('#options-annotation-mode-local').show()
    }
  })
}

$(document).on('turbolinks:load', function() {
  // show/hide streaming options based on configuration
  if ($('#twitter-streaming-options').data('active-stream')) {
    $('#twitter-streaming-options').show();
  } else {
    $('#twitter-streaming-options').hide();
  }
  toggleTwitterOptions();
  // show/hide annotation mode options based on configuration
  if ($('#select-annotation-mode').val() == 0) {
    $('#options-annotation-mode-local').hide()
  } else {
    $('#options-annotation-mode-local').show()
  }
  annotationModeSelect();
})
