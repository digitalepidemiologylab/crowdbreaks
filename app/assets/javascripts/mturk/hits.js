function toggleSandbox() {
  $('#sandbox-checkbox').change(function() {
    var url = new URL(window.location.href);
    url.searchParams.delete('page')
    url.searchParams.delete('next_token')
    url.searchParams.delete('sandbox')
    if($(this).is(':checked')) {
      url.searchParams.append('sandbox', true)
    } else {
      url.searchParams.append('sandbox', false)
    }
    window.location.href = url.href
  });
}

$(document).on('turbolinks:load', function() {
  toggleSandbox();
})
