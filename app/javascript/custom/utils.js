import moment from 'moment';

function convertTimeAgo() {
  $('.convert-by-moment').each(function() {
    let lang = $(this).data('lang');
    moment.locale(lang);
    let timeAt = moment($(this).text());
    if (timeAt.isValid()) {
      $(this).text(timeAt.fromNow());
      $(this).attr('title', timeAt.format()).data('toggle', 'tooltip').tooltip();
    } else {
      console.error('Provided time is not valid and cannot be converted by moment.')
    }
  });
}

$(document).on('turbolinks:load', () => {
  convertTimeAgo();
});
