// React
import React from 'react'
import PropTypes from 'prop-types';

// Components
import { QuestionSequence } from './../components/QuestionSequence';

export class MturkQSContainer extends React.Component {
  constructor(props) {
    super(props);
  }

  postData(resultData) {
    $.ajax({
      type: "POST",
      url: this.props.resultsPath,
      data: resultData,
    });
  }
  
  render() {
    return(
      <QuestionSequence 
        initialQuestionId={this.props.initialQuestionId}
        questions={this.props.questions}
        transitions={this.props.transitions}
        tweetId={this.props.tweetId}
        projectsPath={this.props.projectsPath}
        translations={this.props.translations}
        userId={this.props.userId}
        projectId={this.props.projectId}
        postData={(args) => this.postData(args)}
      />); 
  }
}

MturkQSContainer.propTypes = {
  initialQuestionId: PropTypes.number,
  questions: PropTypes.object,
  transitions: PropTypes.object,
  tweetId: PropTypes.string,
  projectsPath: PropTypes.string,
  resultsPath: PropTypes.string,
  translations: PropTypes.object,
  userId: PropTypes.number,
  projectId: PropTypes.number,
}
