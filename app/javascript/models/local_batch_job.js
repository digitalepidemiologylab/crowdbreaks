function toggleMturkMode() {
  $('#mturk-checkbox').change(function() {
    let url = new URL(window.location.href);
    url.searchParams.delete('mturk_mode')
    if($(this).is(':checked')) {
      url.searchParams.append('mturk_mode', true)
    } else {
      url.searchParams.append('mturk_mode', false)
    }
    window.location.href = url.href
  });
}

$(document).on('turbolinks:load', function() {
  toggleMturkMode();
})
