// React
import React from 'react'
import PropTypes from 'prop-types';

import { QuestionSequence } from './QuestionSequence';
import { Final } from './Final';


export class QSContainer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      'questionSequenceHasEnded': false
    };
  }

  postData(resultData) {
    $.ajax({
      type: "POST",
      url: this.props.resultsPath,
      data: resultData,
    });
    return true;
  }

  onTweetLoadError() {
    // Todo: handle exception
    console.log("Tweet not available anymore");
  }

  onQuestionSequenceEnd() {
    // remember user has answered tweet
    var data = {
      'api': {
        'tweet_id': this.props.tweetId,
        'user_id': this.props.userId,
        'project_id': this.props.projectId
      }
    };
    $.ajax({
      type: "POST",
      url: this.props.endQuestionSequencePath,
      data: data,
    });
    
    this.setState({
      'questionSequenceHasEnded': true
    });
  }

  onNextQuestionSequence() {
    // simply reload page to get new question sequence
    window.location.reload(false);
  }

  render() {
    let body = null;
    if (!this.state.questionSequenceHasEnded) {
      body = <QuestionSequence 
        projectTitle={this.props.projectTitle}
        initialQuestionId={this.props.initialQuestionId}
        questions={this.props.questions}
        transitions={this.props.transitions}
        tweetId={this.props.tweetId}
        projectsPath={this.props.projectsPath}
        userId={this.props.userId}
        projectId={this.props.projectId}
        postData={(args) => this.postData(args)}
        onTweetLoadError={() => this.onTweetLoadError()}
        onQuestionSequenceEnd={() => this.onQuestionSequenceEnd()}
        numTransitions={this.props.numTransitions}
      /> 
    } else {
      body = <Final 
        onNextQuestionSequence={() => this.onNextQuestionSequence()}
        projectsPath={this.props.projectsPath}
        translations={this.props.translations}
      /> 
    }
    return(
      <div>
        {body}
      </div>
    );
  }
}

QSContainer.propTypes = {
  projectTitle: PropTypes.string,
  initialQuestionId: PropTypes.number,
  questions: PropTypes.object,
  transitions: PropTypes.object,
  tweetId: PropTypes.string,
  projectsPath: PropTypes.string,
  endQuestionSequencePath: PropTypes.string,
  resultsPath: PropTypes.string,
  translations: PropTypes.object,
  userId: PropTypes.number,
  projectId: PropTypes.number,
  numTransitions: PropTypes.number
}
