// React
import React from 'react'

// Other
let humps = require('humps');
import { QSLogger } from './QSLogger';

// Sub-components
import { QuestionSequence } from './QuestionSequence';
import { LocalBatchFinal } from './LocalBatchFinal';
import { LocalBatchNoMoreWork } from './LocalBatchFinal';
import { LocalBatchTweetNotAvailable } from './LocalBatchFinal';
import { LocalBatchCounts } from './LocalBatchCounts';
import { InstructionModal } from './InstructionModal';
import { Instructions } from './Instructions';

export class LocalBatchQSContainer extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      'questionSequenceHasEnded': false,
      'nextTweetId': 0,
      'tweetId': props.tweetId,
      'tweetText': props.tweetText,
      'questions': props.questions,
      'errors': [],
      'noWorkAvailable': props.noWorkAvailable,
      'userCount': props.userCount,
      'totalCount': props.totalCount,
      'totalCountUnavailable': props.totalCountUnavailable,
      'tweetIsAvailable': props.tweetIsAvailable,
      'nextTweetIsAvailable': true,
      'displayInstructions': false,
      'currentQuestion': props.questions[props.initialQuestionId],
      'numQuestionsAnswered': 0,
      'results': [],
    };

    this.log = new QSLogger(props.answersDelay);
  }

  componentDidMount() {
    this.log.logMounted()
  }

  onAnswerSubmit(answerId) {
    // Log result
    this.log.logResult(this.state.currentQuestion.id);
    // collect result data
    let resultData = humps.decamelizeKeys({
      result: {
        answerId: answerId,
        questionId: this.state.currentQuestion.id,
        userId: this.props.userId,
        tweetId: this.props.tweetId,
        projectId: this.props.projectId
      }
    });
    // Increment answer counter
    this.setState({
      results: this.state.results.concat([resultData]),
      numQuestionsAnswered: this.state.numQuestionsAnswered + 1,
    })
  }

  onQuestionSequenceEnd() {
    let data = humps.decamelizeKeys({
      qs: {
        tweetId: this.state.tweetId,
        userId: this.props.userId,
        projectId: this.props.projectId,
        results: this.state.results,
      }
    });
    data['qs']['logs'] = this.log.getLog();

    $.ajax({
      type: "POST",
      url: this.props.endQuestionSequencePath,
      data: JSON.stringify(data),
      contentType: "application/json",
      success: (response) => {
        let tweetId = response['tweet_id'];
        if (tweetId == "") {
          // No more work to be done
          this.setState({
            'noWorkAvailable': true,
            'questionSequenceHasEnded': true
          });
        } else {
          this.setState({
            'nextTweetId': tweetId,
            'nextTweetIsAvailable': response['tweet_is_available'],
            'tweetText': response['tweet_text'],
            'questionSequenceHasEnded': true,
            'userCount': response['user_count'],
            'totalCount': response['total_count'],
            'totalCountUnavailable': response['total_count_unavailable'],
            'noWorkAvailable': response['no_work_available'],
          });
        }
      }
    });
  }

  onNextQuestionSequence() {
    // Reset logging
    this.log.reset();

    if (this.state.nextTweetId == 0 || isNaN(this.state.nextTweetId || this.state.nextTweetId == this.state.tweetId)) {
      // Something went wrong, simply reload page to get new question sequence
      window.location.reload(false);
    } else {
      this.setState({
        tweetId: this.state.nextTweetId,
        tweetIsAvailable: this.state.nextTweetIsAvailable,
        questionSequenceHasEnded: false,
        openModal: false,
        nextTweetId: 0,
        currentQuestion: this.props.questions[this.props.initialQuestionId],
        numQuestionsAnswered: 0,
        results: [],
      });
    }
  }

  gotoNextQuestion(nextQuestion) {
    // Go to next question
    this.setState({
      'currentQuestion': this.props.questions[nextQuestion],
    });
  }

  onTweetLoadError() {
    this.setState({
      errors: this.state.errors.concat(["Error when trying to load tweet. Ensure you disable browser plugins which may block this content."])
    });
  }

  onToggleInstructionDisplay() {
    this.setState({
      displayInstructions: !this.state.displayInstructions
    })
  }


  getQuestionSequence() {
    if (this.state.noWorkAvailable) {
      return <LocalBatchNoMoreWork 
        exitPath={this.props.exitPath}
        totalCount={this.state.totalCount}
        /> 
    }
    if (!this.state.tweetIsAvailable) {
      return <LocalBatchTweetNotAvailable 
        onNextQuestionSequence={() => this.onNextQuestionSequence()}
        exitPath={this.props.exitPath}
        tweetId={this.state.tweetId}
        /> 
    }
    if (!this.state.questionSequenceHasEnded) {
      return <QuestionSequence 
          ref={qs => {this.questionSequence = qs;}}
          questions={this.state.questions}
          currentQuestion={this.state.currentQuestion}
          transitions={this.props.transitions}
          tweetId={this.state.tweetId}
          tweetText={this.state.tweetText}
          userId={this.props.userId}
          projectId={this.props.projectId}
          onTweetLoadError={() => this.onTweetLoadError()}
          onAnswerSubmit={(answerId) => this.onAnswerSubmit(answerId)}
          onQuestionSequenceEnd={() => this.onQuestionSequenceEnd()}
          gotoNextQuestion={(nextQuestion) => this.gotoNextQuestion(nextQuestion)}
          numTransitions={this.props.numTransitions}
          captchaSiteKey={""}
          userSignedIn={true}
          captchaVerified={true}
          answersDelay={this.props.answersDelay}
          displayQuestionInstructions={true}
          numQuestionsAnswered={this.state.numQuestionsAnswered}
        /> 
    } else {
      return <LocalBatchFinal 
        onNextQuestionSequence={() => this.onNextQuestionSequence()}
        exitPath={this.props.exitPath}
      /> 
    }
  }

  render() {
    let body = this.getQuestionSequence()
    let counts = <div className="mb-3">
      <LocalBatchCounts 
        noWorkAvailable={this.state.noWorkAvailable}
        testMode={this.props.testMode}
        userCount={this.state.userCount}
        totalCount={this.state.totalCount}
        totalCountUnavailable={this.state.totalCountUnavailable}
        userName={this.props.userName}
        tweetTextAvailable={(this.state.tweetText == "" || this.state.tweetText === undefined) ? false : true}
      />
    </div>;
    let title = this.props.projectTitle && <h4 className="mb-4">
      {this.props.projectTitle}
    </h4>;
    let instructions = <div className="mb-4">
      <Instructions
        display={this.state.displayInstructions}
        instructions={this.props.instructions}
        onToggleDisplay={() => this.onToggleInstructionDisplay()}
      />
    </div>;
    let errors = this.state.errors.length > 0 && <ul className='qs-error-notifications'>
      <li>Error:</li>
      {this.state.errors.map(function(error, i) {
        return <li key={i}>{error}</li>
      })}
    </ul>
    return(
      <div>
        {title}
        {counts}
        {instructions}
        {errors}
        {body}
      </div>
    );
  }
}
