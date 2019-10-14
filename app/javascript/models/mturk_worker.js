function onCorrectingMturkWorkerClick() {
  $('.default-mturk-worker-result').each(function () {
    $(this).on("click", function () {
      $(this).hide();
      $(this).siblings('.incorrect-mturk-worker-result').show()

    });
  });

  $('.incorrect-mturk-worker-result').each(function () {
    $(this).on("click", function () {
      $(this).hide();
      $(this).siblings('.correct-mturk-worker-result').show()
    });
  });

  $('.correct-mturk-worker-result').each(function () {
    $(this).on("click", function () {
      $(this).hide();
      $(this).siblings('.default-mturk-worker-result').show()
    });
  });
}

$(document).on('turbolinks:load', function() {
  onCorrectingMturkWorkerClick();
})
