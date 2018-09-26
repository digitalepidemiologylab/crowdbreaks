// React
import React from 'react'

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
      'transitions': props.transitions,
      'questions': props.questions,
      'errors': [],
      'noWorkAvailable': props.noWorkAvailable,
      'userCount': props.userCount,
      'totalCount': props.totalCount,
      'totalCountUnavailable': props.totalCountUnavailable,
      'tweetIsAvailable': props.tweetIsAvailable,
      'nextTweetIsAvailable': true,
      'displayInstructions': false
    };
  }

  submitResult(resultData) {
    // Nothing to do here
    return true;
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

  onQuestionSequenceEnd(results, logs) {
    var data = {
      'qs': {
        'tweet_id': this.state.tweetId,
        'user_id': this.props.userId,
        'project_id': this.props.projectId,
        'results': results,
        'logs': logs
      }
    };

    $.ajax({
      type: "POST",
      url: this.props.endQuestionSequencePath,
      data: JSON.stringify(data),
      contentType: "application/json",
      success: (response) => {
        var tweetId = response['tweet_id'];
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
            'noWorkAvailable': response['no_work_available']
          });
        }
      }
    });
  }

  onNextQuestionSequence() {
    if (this.state.nextTweetId == 0 || isNaN(this.state.nextTweetId || this.state.nextTweetId == this.state.tweetId)) {
      // Something went wrong, simply reload page to get new question sequence
      window.location.reload(false);
    } else {
      this.setState({
        tweetId: this.state.nextTweetId,
        tweetIsAvailable: this.state.nextTweetIsAvailable,
        questionSequenceHasEnded: false,
        openModal: false,
        nextTweetId: 0
      });
    }
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
          initialQuestionId={this.props.initialQuestionId}
          questions={this.state.questions}
          transitions={this.state.transitions}
          tweetId={this.state.tweetId}
          tweetText={this.state.tweetText}
          userId={this.props.userId}
          projectId={this.props.projectId}
          submitResult={(args) => this.submitResult(args)}
          onTweetLoadError={() => this.onTweetLoadError()}
          onQuestionSequenceEnd={(results, logs) => this.onQuestionSequenceEnd(results, logs)}
          numTransitions={this.props.numTransitions}
          captchaSiteKey={""}
          userSignedIn={true}
          captchaVerified={true}
          enableAnswersDelay={this.props.enableAnswersDelay}
          displayQuestionInstructions={false}
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
