// React
import React from 'react'

import { QuestionSequence } from './QuestionSequence';
import { Final } from './Final';
import { InstructionModal } from './InstructionModal';


export class QSContainer extends React.Component {
  constructor(props) {
    super(props);

    // By default set test mode to false
    let testMode = props.testMode
    if (testMode === undefined) {
      testMode = false;
    }

    this.state = {
      'questionSequenceHasEnded': false,
      'captchaVerified': !props.enableCaptcha,  // if captcha is disabled, sets captcha permanently to verified state
      'nextTweetId': 0,
      'tweetId': props.tweetId,
      'transitions': props.transitions,
      'numTransitions': props.numTransitions,
      'questions': props.questions,
      'openModal': !props.userSignedIn,
      'errors': [],
      'testMode': testMode
    };
  }

  submitResult(resultData) {
    if (this.state.testMode) {
      return true;
    }

    if ('recaptcha_response' in resultData) {
      // Make sure to only continue on successful verification
      $.ajax({
        type: "POST",
        url: this.props.resultsPath,
        data: JSON.stringify(resultData),
        contentType: "application/json",
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
        data: JSON.stringify(resultData),
        contentType: "application/json",
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

  onQuestionSequenceEnd(results, logs) {
    // remember user has answered tweet
    var data = {
      'qs': {
        'tweet_id': this.state.tweetId,
        'user_id': this.props.userId,
        'project_id': this.props.projectId,
        'logs': logs,
        'test_mode': this.state.testMode
      }
    };
    // Note: results contains a collection of all previous results which is not used here but may be used by other container components

    $.ajax({
      type: "POST",
      url: this.props.endQuestionSequencePath,
      data: JSON.stringify(data),
      contentType: "application/json",
      success: (response) => {
        var tweet_id = response['tweet_id'];
        this.setState({
          nextTweetId: tweet_id
        });
      }
    });
    
    this.setState({
      'questionSequenceHasEnded': true
    });
  }

  onNextQuestionSequence() {
    if (this.state.nextTweetId == 0 || isNaN(this.state.nextTweetId)) {
      // Something went wrong, simply reload page to get new question sequence
      window.location.reload(false);
    } else {
      this.setState({
        tweetId: this.state.nextTweetId,
        questionSequenceHasEnded: false,
        openModal: false,
        nextTweetId: 0
      });
    }
  }

  render() {
    let body = null;

    if (!this.state.questionSequenceHasEnded) {
      body = <div>
        <InstructionModal 
          openModal={this.state.openModal}
          projectsPath={this.props.projectsPath}
        />
        <QuestionSequence 
          ref={qs => {this.questionSequence = qs;}}
          projectTitle={this.props.projectTitle}
          initialQuestionId={this.props.initialQuestionId}
          questions={this.state.questions}
          transitions={this.state.transitions}
          tweetId={this.state.tweetId}
          userId={this.props.userId}
          projectId={this.props.projectId}
          submitResult={(args) => this.submitResult(args)}
          onTweetLoadError={() => this.onTweetLoadError()}
          onQuestionSequenceEnd={(results, logs) => this.onQuestionSequenceEnd(results, logs)}
          numTransitions={this.state.numTransitions}
          captchaSiteKey={this.props.captchaSiteKey}
          userSignedIn={this.props.userSignedIn}
          captchaVerified={this.state.captchaVerified}
          enableAnswersDelay={this.props.enableAnswersDelay}
          displayQuestionInstructions={false}
        /> 
      </div>
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
