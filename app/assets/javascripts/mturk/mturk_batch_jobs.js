function convertUnitsBeforeSubmit() {
  $('#mturk-batch-job-form').submit(function(e) {
    // convert days -> s
    $('input#mturk_batch_job_lifetime_in_seconds')[0].value *= 24*3600;
    $('input#mturk_batch_job_auto_approval_delay_in_seconds')[0].value *= 24*3600;
    // convert min -> s
    $('input#mturk_batch_job_assignment_duration_in_seconds')[0].value *= 60;
    return true;
  });
}

$(document).on('turbolinks:load', function() {
  convertUnitsBeforeSubmit();
})
