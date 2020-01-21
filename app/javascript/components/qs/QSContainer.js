// React
import React from 'react'

// Other
let humps = require('humps');
import { QSLogger } from './QSLogger';

// Components
import { QuestionSequence } from './QuestionSequence';
import { Final } from './Final';
import { InstructionModal } from './InstructionModal';

export class QSContainer extends React.Component {
  constructor(props) {
    super(props);
    if (!props.userSignedIn && !props.captchaVerified) {
      // Note: This could lead to problems if a user has multiple Question sequences in one window
      window.onCaptchaVerify = this.verifyCallback.bind(this);
    }

    // By default set test mode to false
    this.testMode = props.testMode
    if (this.testMode === undefined) {
      this.testMode = false;
    }

    this.state = {
      'questionSequenceHasEnded': false,
      'captchaVerified': !props.enableCaptcha,  // if captcha is disabled, sets captcha permanently to verified state
      'tweetId': props.tweetId,
      'openModal': !props.userSignedIn,
      'errors': [],
      'nextTweetId': 0,
      'currentQuestion': props.questions[props.initialQuestionId],
      'unverifiedAnswers': [],
      'numQuestionsAnswered': 0,
    };

    this.log = new QSLogger(props.delayStart, props.delayNextQuestion);
  }

  componentDidMount() {
    this.log.logMounted()
  }

  onAnswerSubmit(answerId, time) {
    // Increment answer counter
    this.setState({
      numQuestionsAnswered: this.state.numQuestionsAnswered + 1
    })
    // Log result
    this.log.logResult(this.state.currentQuestion.id, time);
    // Exit in case of test mode
    if (this.testMode) {
      return true;
    }
    // Send single result
    let resultData = humps.decamelizeKeys({
      result: {
        answerId: answerId,
        questionId: this.state.currentQuestion.id,
        userId: this.props.userId,
        tweetId: this.state.tweetId,
        projectId: this.props.projectId
      }
    });
    // Captcha verification
    if (!this.props.userSignedIn && !this.state.captchaVerified) {
      // add to waiting queue to be verified by captcha
      this.state.unverifiedAnswers.push(resultData);
      // trigger captcha verification
      grecaptcha.execute();
    } else {
      $.ajax({
        type: "POST",
        url: this.props.resultsPath,
        data: JSON.stringify(resultData),
        contentType: "application/json",
        error: (response) => {
          let errors = response['responseJSON']['errors'];
          this.setState({
            errors: this.state.errors.concat(errors)
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

  onQuestionSequenceEnd(time) {
    this.log.logFinal(time);
    let data = humps.decamelizeKeys({
      qs: {
        tweetId: this.state.tweetId,
        userId: this.props.userId,
        projectId: this.props.projectId,
        testMode: this.testMode,
      }
    });
    data['qs']['logs'] = this.log.getLog();
    $.ajax({
      type: "POST",
      url: this.props.endQuestionSequencePath,
      data: JSON.stringify(data),
      contentType: "application/json",
      success: (response) => {
        let tweet_id = response['tweet_id'];
        this.setState({
          nextTweetId: tweet_id
        });
      }
    });
    this.setState({
      'questionSequenceHasEnded': true
    });
  }

  gotoNextQuestion(nextQuestion) {
    // Go to next question
    this.setState({
      'currentQuestion': this.props.questions[nextQuestion],
    });
  }

  onNextQuestionSequence() {
    // Reset logging
    this.log.reset();

    if (this.state.nextTweetId == 0 || isNaN(this.state.nextTweetId)) {
      // Something went wrong, simply reload page to get new question sequence
      window.location.reload(false);
    } else {
      this.setState({
        tweetId: this.state.nextTweetId,
        questionSequenceHasEnded: false,
        openModal: false,
        nextTweetId: 0,
        currentQuestion: this.props.questions[this.props.initialQuestionId],
        unverifiedAnswers: [],
        numQuestionsAnswered: 0,
        errors: [],
      });
    }
  }

  verifyCallback(response) {
    // executed once the captcha has been verified
    let resultData;
    // Post any unverified data to server
    while (this.state.unverifiedAnswers.length > 0) {
      resultData = this.state.unverifiedAnswers.pop()
      resultData['recaptcha_response'] = response;
      $.ajax({
        type: "POST",
        url: this.props.resultsPath,
        data: JSON.stringify(resultData),
        contentType: "application/json",
        success: (response) => {
          if (response['captcha_verified']) {
            this.setState({
              captchaVerified: true
            })
            return true;
          }
          return false;
        },
        error: (response) => {
          let errors = response['responseJSON']['errors'];
          this.setState({
            errors: this.state.errors.concat(errors)
          });
          return false;
        }
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
          translations={this.props.translations.instruction_modal}
        />
        <QuestionSequence
          ref={qs => {this.questionSequence = qs;}}
          projectTitle={this.props.projectTitle}
          questions={this.props.questions}
          currentQuestion={this.state.currentQuestion}
          transitions={this.props.transitions}
          tweetId={this.state.tweetId}
          userId={this.props.userId}
          projectId={this.props.projectId}
          onTweetLoadError={() => this.onTweetLoadError()}
          onQuestionSequenceEnd={(time) => this.onQuestionSequenceEnd(time)}
          onAnswerSubmit={(answerId, time) => this.onAnswerSubmit(answerId, time)}
          gotoNextQuestion={(nextQuestion) => this.gotoNextQuestion(nextQuestion)}
          numTransitions={this.props.numTransitions}
          captchaSiteKey={this.props.captchaSiteKey}
          userSignedIn={this.props.userSignedIn}
          captchaVerified={this.state.captchaVerified}
          delayStart={this.props.delayStart}
          delayNextQuestion={this.props.delayNextQuestion}
          displayQuestionInstructions={false}
          numQuestionsAnswered={this.state.numQuestionsAnswered}
          translations={this.props.translations}
          colorOptions={this.props.colorOptions}
        />
      </div>
    } else {
      body = <Final
        onNextQuestionSequence={() => this.onNextQuestionSequence()}
        projectsPath={this.props.projectsPath}
        translations={this.props.translations.final}
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
