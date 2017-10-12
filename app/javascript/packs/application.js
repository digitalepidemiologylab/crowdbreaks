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
    var data_attr = $(div_to_render_in).data();
    render(
      <QSContainer 
        initialQuestionId={data_attr.initialQuestionId}
        questions={data_attr.questions}
        transitions={data_attr.transitions}
        tweetId={data_attr.tweetId}
        projectsPath={data_attr.projectsPath}
        resultsPath={data_attr.resultsPath}
        translations={data_attr.translations}
        locale={data_attr.locale}
        userId={data_attr.userId}
      />, div_to_render_in);
  }
});
