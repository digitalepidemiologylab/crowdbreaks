/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

import React from 'react';
import { render } from 'react-dom';
import { QSContainer } from './../components/QSContainer';

document.addEventListener('turbolinks:load', () => {
  var div_to_render_in = document.getElementById('question-sequence-component');
  if (div_to_render_in) {
    var initialQuestionId = div_to_render_in.dataset.initialQuestionId;
    var questions = JSON.parse(div_to_render_in.dataset.questions);
    var transitions = JSON.parse(div_to_render_in.dataset.transitions);
    var tweetId = div_to_render_in.dataset.tweetId;
    var projectsPath = div_to_render_in.dataset.projectsPath;
    var translations = JSON.parse(div_to_render_in.dataset.translations);
    var locale = div_to_render_in.dataset.locale;
    render(
      <QSContainer 
        initialQuestionId={initialQuestionId}
        questions={questions}
        transitions={transitions}
        tweetId={tweetId}
        projectsPath={projectsPath}
        translations={translations}
        locale={locale}
      />, div_to_render_in);
  }
});
