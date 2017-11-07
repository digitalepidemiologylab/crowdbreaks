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
import { MturkQSContainer } from './../components/MturkQSContainer';

document.addEventListener('turbolinks:load', () => {
  var div_qs = document.getElementById('question-sequence-component');
  var div_qs_mturk = document.getElementById('mturk-question-sequence-component');

  // Question sequence component
  if (div_qs) {
    var data_attr = $(div_qs).data();
    render(
      <QSContainer 
        initialQuestionId={data_attr.initialQuestionId}
        questions={data_attr.questions}
        transitions={data_attr.transitions}
        tweetId={data_attr.tweetId.toString()}
        projectsPath={data_attr.projectsPath}
        resultsPath={data_attr.resultsPath}
        translations={data_attr.translations}
        userId={data_attr.userId}
        projectId={data_attr.projectId}
      />, div_qs);
  }

  // Mturk question sequence component
  if (div_qs_mturk) {
    var data_attr = $(div_qs_mturk).data();
    render(
      <MturkQSContainer 
        initialQuestionId={data_attr.initialQuestionId}
        questions={data_attr.questions}
        transitions={data_attr.transitions}
        tweetId={data_attr.tweetId.toString()}
        projectsPath={data_attr.projectsPath}
        resultsPath={data_attr.resultsPath}
        translations={data_attr.translations}
        userId={data_attr.userId}
        projectId={data_attr.projectId}
        assignmentId={data_attr.assignmentId.toString()}
        previewMode={data_attr.previewMode}
      />, div_qs_mturk);
  }
});
