// React
import React from 'react'
import PropTypes from 'prop-types';

import { QuestionSequence } from './QuestionSequence';
import { Final } from './Final';


export class QSContainer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      'questionSequenceHasEnded': false,
      'captchaVerified': false,
      'nextQuestionSequence': [],
      'tweetId': props.tweetId,
      'transitions': props.transitions,
      'numTransitions': props.numTransitions,
      'questions': props.questions,
      'errors': []
    };
  }

  postData(resultData) {
    if ('recaptcha_response' in resultData) {
      // Make sure to only continue on successful verification
      $.ajax({
        type: "POST",
        url: this.props.resultsPath,
        data: resultData,
        success: (response) => {
          if (response['captcha_verified']) {
            console.log('successfully verified captcha');
            this.setState({
              captchaVerified: true
            })
            return true;
          }
          return false;
        },
        error: (response) => {
          var errors = response['responseJSON']['errors'];
          this.setState({
            errors: this.state.errors.concat(errors)
          });
          return false;
        }
      });
    } else {
      $.ajax({
        type: "POST",
        url: this.props.resultsPath,
        data: resultData,
        error: (response) => {
          this.setState({
            errors: this.state.errors.concat(['Internal error'])
          });
        }
      });
      // Continue even on error
      return true;
    }
  }

  onTweetLoadError() {
    // Todo: handle exception
    this.setState({
      errors: this.state.errors.concat(['Tweet not available anymore'])
    });
  }

  onQuestionSequenceEnd() {
    // remember user has answered tweet
    var data = {
      'qs': {
        'tweet_id': this.state.tweetId,
        'user_id': this.props.userId,
        'project_id': this.props.projectId
      }
    };
    $.ajax({
      type: "POST",
      url: this.props.endQuestionSequencePath,
      data: data,
      success: (response) => {
        this.setState({
          nextQuestionSequence: [response]
        });
      }
    });
    
    this.setState({
      'questionSequenceHasEnded': true
    });
  }

  onNextQuestionSequence() {
    if (this.state.nextQuestionSequence.length == 0) {
      // Something went wrong, simply reload page to get new question sequence
      window.location.reload(false);
    } else {
      var nextQuestionSequence = this.state.nextQuestionSequence.pop();
      this.setState({
        tweetId: nextQuestionSequence.tweet_id,
        transitions: nextQuestionSequence.transitions,
        numTransitions: nextQuestionSequence.num_transitions,
        questions: nextQuestionSequence.questions,
        questionSequenceHasEnded: false,
        nextQuestionSequence: []
      });
    }
  }

  render() {
    let body = null;
    if (!this.state.questionSequenceHasEnded) {
      body = <QuestionSequence 
        projectTitle={this.props.projectTitle}
        initialQuestionId={this.props.initialQuestionId}
        questions={this.state.questions}
        transitions={this.state.transitions}
        tweetId={this.state.tweetId}
        projectsPath={this.props.projectsPath}
        userId={this.props.userId}
        projectId={this.props.projectId}
        postData={(args) => this.postData(args)}
        onTweetLoadError={() => this.onTweetLoadError()}
        onQuestionSequenceEnd={() => this.onQuestionSequenceEnd()}
        numTransitions={this.state.numTransitions}
        captchaSiteKey={this.props.captchaSiteKey}
        userSignedIn={this.props.userSignedIn}
        captchaVerified={this.state.captchaVerified}
      /> 
    } else {
      body = <Final 
        onNextQuestionSequence={() => this.onNextQuestionSequence()}
        projectsPath={this.props.projectsPath}
        translations={this.props.translations}
      /> 
    }
    let errors = this.state.errors.length > 0 && <ul className='qs-error-notifications'>
      <li>Error:</li>
      {this.state.errors.map(function(error, i) {
        return <li key={i}>{error}</li>
      })}
    </ul>
    return(
      <div>
        {errors}
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
  numTransitions: PropTypes.number,
  captchaSiteKey: PropTypes.string
}
