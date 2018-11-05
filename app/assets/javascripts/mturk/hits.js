function onUpdateMturkHitsComplete() {
  console.log('update completed')
  $('#refresh-mturk-hits-spinner').hide();
  $('#refresh-mturk-hits').show();
  $('#refresh-mturk-hits-spinner-info').hide();
  // Reload will show new data
  if (window.location.pathname.endsWith('mturk_hits')) {
    window.location.reload();
  }
}


function onRefreshMturkHits() {
  $('#refresh-mturk-hits').bind('ajax:beforeSend', function() {
    $(this).prop('disabled', true);
    $(this).hide();
    $('#refresh-mturk-hits-spinner').show()
    $('#refresh-mturk-hits-spinner-info').text('Refreshing Mturk HITs. This may take a while...');
    $('#refresh-mturk-hits-spinner-info').css('display', 'inline-block');
    $('#refresh-mturk-hits-spinner-info').show();
  })
  $('#refresh-mturk-hits').on('ajax:error', function(e) {
    $('#refresh-mturk-hits-spinner').hide()
    $('#refresh-mturk-hits-spinner-info').text('Refreshing Mturk HITs failed. Try again later...');
    $('#refresh-mturk-hits-spinner-info').css('display', 'inline-block');
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

$(document).on('turbolinks:load', function() {
  toggleSandbox();
  toggleFiltered();
  onRefreshMturkHits();
})
