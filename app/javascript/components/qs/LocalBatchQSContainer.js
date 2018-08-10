// React
import React from 'react'

import { QuestionSequence } from './QuestionSequence';
import { LocalBatchFinal } from './LocalBatchFinal';
import { LocalBatchNoMoreWork } from './LocalBatchFinal';
import { InstructionModal } from './InstructionModal';


export class LocalBatchQSContainer extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      'questionSequenceHasEnded': false,
      'nextTweetId': 0,
      'tweetId': props.tweetId,
      'transitions': props.transitions,
      'questions': props.questions,
      'errors': [],
      'noWorkAvailable': props.noWorkAvailable,
      'userCount': props.userCount,
      'totalCount': props.totalCount
    };
  }

  submitResult(resultData) {
    // Nothing to do here
    return true;
  }

  onTweetLoadError() {
    // Todo: handle exception
    this.setState({
      errors: this.state.errors.concat(['Error when trying to load tweet'])
    });
  }

  onQuestionSequenceEnd(results) {
    var data = {
      'qs': {
        'tweet_id': this.state.tweetId,
        'user_id': this.props.userId,
        'project_id': this.props.projectId,
        'results': results
      }
    };

    this.setState({
      'userCount': this.state.userCount + 1
    });

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
          tweetId = this.validateTweetId(tweetId)
          this.setState({
            nextTweetId: tweetId,
            'questionSequenceHasEnded': true
          });
        }
      }
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

  validateTweetId(tweetId) {
    return tweetId;
  }

  getCounts() {
    if (this.state.noWorkAvailable) {
      return null;
    }
    if (this.state.userCount == 0) {
      return <p>Welcome {this.props.userName}! Feel free to start your batch.</p>
    } else {
      return <p>Keep going! You have finished {this.state.userCount} out of {this.props.totalCount} tweets.</p>
    }
  }


  getQuestionSequence() {
    if (this.state.noWorkAvailable) {
      return <LocalBatchNoMoreWork 
        exitPath={this.props.exitPath}
        totalCount={this.props.totalCount}
        /> 
    }
    if (!this.state.questionSequenceHasEnded) {
      return <QuestionSequence 
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
          onQuestionSequenceEnd={(args) => this.onQuestionSequenceEnd(args)}
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
    let counts = this.getCounts()
    let errors = this.state.errors.length > 0 && <ul className='qs-error-notifications'>
      <li>Error:</li>
      {this.state.errors.map(function(error, i) {
        return <li key={i}>{error}</li>
      })}
    </ul>
    return(
      <div>
        {counts}
        {errors}
        {body}
      </div>
    );
  }
}
