function twitterWidget() {
  window.twttr = (function (d, s, id) {
    var t, js, fjs = $("body");
    if (d.getElementById(id)) return;
    js = d.createElement(s); js.id = id;
    js.src= "https://platform.twitter.com/widgets.js";
    $(fjs).append(js, fjs);
    return window.twttr || (t = { _e: [], ready: function (f) { 
      t._e.push(f) }  });
  }(document, "script", "twitter-wjs"));
};

// only run script in question answer dialog
$(document).on('turbolinks:load', checkForTweet);
jQuery.fn.exists = function(){ return this.length > 0;  }
function checkForTweet() {
  if ($("#question-answer-container").exists()) {
    twitterWidget();
  }
}

