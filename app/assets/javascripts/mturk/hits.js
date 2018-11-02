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

$(document).on('turbolinks:load', function() {
  toggleSandbox();
  toggleFiltered();
})
