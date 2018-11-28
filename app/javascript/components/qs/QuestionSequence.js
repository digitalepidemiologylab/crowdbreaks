// React
import React from 'react'
import ReactCSSTransitionGroup from 'react-addons-css-transition-group';
import { ClipLoader } from 'react-spinners';

// Other 
let humps = require('humps');

// Sub-components
import { Answer } from './Answer';
import { Question } from './Question';
import { QuestionInstructions } from './QuestionInstructions';
import { TweetEmbedding } from './TweetEmbedding';
import { TweetTextEmbedding } from './TweetTextEmbedding';

/*
This component exposes the following callbacks (results and current question state are handled by parent)
- onAnswerSubmit(answerId, time): User clicked on answer button with time
- onQuestionSequenceEnd(time): Question sequence has ended
- gotoNextQuestion: Question sequence has not ended, go to next question
- onTweetLoadError
- onCaptchaVerify: Executed once Captcha has been verified
*/

export class QuestionSequence extends React.Component {
  constructor(props) {
    super(props);
    // Check if tweet text is provided
    let tweetTextPresent = true;
    if (props.tweetText == "" || props.tweetText === undefined) {
      tweetTextPresent = false;
    }
    // set initial question state
    this.state = {
      'tweetIsLoading': !tweetTextPresent,
      'showTweetText': tweetTextPresent,
      'answersDisabled': true,
      'showQuestionInstruction': false,
    };
  }

  componentDidMount() {
    // Enable Answer delay at this moment in case of showing tweet text
    if (this.state.showTweetText) {
      this.delayEnableAnswers();
    }
  }

  nextQuestion(currentQuestionId, answerId) {
    // case no transitions from current question Id -> end of question sequence
    if (!(currentQuestionId in this.props.transitions)) {
      return null;
    }
    let possible_transitions = this.props.transitions[currentQuestionId];
    // case 1 possible transition
    if (possible_transitions.length == 1) {
      // if answer === null -> allow transition irrespective of answerId
      if (possible_transitions[0].answer === null || possible_transitions[0].answer == answerId) {
        return possible_transitions[0].to_question;
      } else {
        // end of question sequence
        return null;
      }
    }

    // case multiple possible transitions -> check for matching answer
    for (let i=0; i < possible_transitions.length; i++) {
      if(possible_transitions[i].answer == answerId) {
        return possible_transitions[i].to_question;
      }
    }
    // no transitions were found
    return null;
  }

  onAnswerSubmitQS(answerId, time) {
    // update state in parent
    this.props.onAnswerSubmit(answerId, time)
    // find next question
    let nextQuestion = this.nextQuestion(this.props.currentQuestion.id, answerId);
    if (nextQuestion === null) {
      // End of question sequence
      this.setState({
        'tweetHasLoaded': false,
      })
      this.props.onQuestionSequenceEnd(time);
    } else {
      this.props.gotoNextQuestion(nextQuestion)
    }
  }
  
  enableAnswerButtons() {
    this.setState({answersDisabled: false});
  }

  delayEnableAnswers() {
    // Make answer buttons clickable after delay
    setTimeout(() => this.enableAnswerButtons(), this.props.answersDelay);
  }

  onTweetLoad() {
    let style = document.createElement('style')
    style.innerHTML = '.EmbeddedTweet { border-color: #ced7de; max-width: 100%; }'
    try {
      let shadowRoot = this.tweet.querySelector('.twitter-tweet').shadowRoot
      if (shadowRoot != null) {
        shadowRoot.appendChild(style)
        if (shadowRoot.children[1].innerHTML == "") {
          // This can occur when a tweet was set to private, thus is not accessible anymore. Handle this case separately
          console.log("Tweet with id", this.props.tweetId, "could not be loaded.")
          this.props.onTweetLoadError();
        }
      }
    } catch(err) {
      console.log('An error occured while trying to access shadow DOM.')
      console.log(err)
    }
    this.setState({
      'tweetIsLoading': false
    });
    this.delayEnableAnswers();
  }

  toggleQuestionInstructions() {
    this.setState({showQuestionInstruction: !this.state.showQuestionInstruction})
  }

  render() {
    let parentThis = this;
    let progressDots = [];
    let Q = "Q" + (this.props.numQuestionsAnswered+1).toString();
    let tweetEmbedding;
    for (let i = 0; i < this.props.numTransitions; ++i) {
      let liClassName = "";
      if (i < this.props.numQuestionsAnswered) {
        liClassName = "complete"
      } else if (i == this.props.numQuestionsAnswered) {
        liClassName = "current"
      }
      progressDots.push(
        <li className={liClassName} key={i}><span>{i}</span></li>
      )
    }
    if (this.state.showTweetText) {
      tweetEmbedding = <TweetTextEmbedding tweetText={this.props.tweetText} />
    } else {
      tweetEmbedding = <TweetEmbedding tweetId={this.props.tweetId} onTweetLoad={() => this.onTweetLoad()} />
    }
    let questionSequenceBody = <div ref={(tweet) => this.tweet = tweet}>
      {/* Title and tweet */}
      <div className='row justify-content-center'> 
        <div className="col-12">
          {this.props.projectTitle && <h4 className="mb-5">{this.props.projectTitle}</h4>} 
          {tweetEmbedding}
        </div>
      </div>
      {/* Loading clip */}
      { this.state.tweetIsLoading &&
          <div className="row">
            <div className="col-12">
              <div className="clip-loader">
                <ClipLoader
                  color={'#444'} 
                />
              </div>
            </div>
          </div>
      } 
      {/* Circle question number */}
      { !this.state.tweetIsLoading && 
          <div className="row justify-content-center">
            <div className="col-xs-12 col-lg-8 text-center">
              <div className="v-line"></div>
              <h4 className="circle-text mb-4">{Q}</h4>
              {/* Question */}
              <Question 
                question={this.props.currentQuestion.question}
                hasInstructions={this.props.displayQuestionInstructions && this.props.currentQuestion.instructions != ""}
                toggleQuestionInstructions={() => this.toggleQuestionInstructions()}
              />
              {/* Answers */}
              <div className="buttons mb-4">
                {this.props.currentQuestion.answers.map(function(answer) {
                  return <Answer 
                    key={answer.id} 
                    answer={answer.answer} 
                    disabled={parentThis.state.answersDisabled}
                    submit={() => parentThis.onAnswerSubmitQS(answer.id, new Date().getTime())}
                    color={answer.color}
                  />
                })}
              </div>
              {/* Progress dots */}
              <ul className="progress-dots">
                { progressDots }
              </ul>
            </div> 
          </div> 
      }
      {/* Invisible recaptcha */}
      {!this.props.userSignedIn && !this.props.captchaVerified &&
          <div className="g-recaptcha"
            data-sitekey={this.props.captchaSiteKey}
            data-callback="onCaptchaVerify"
            data-size="invisible">
          </div>
      }
    </div>
      let questionInstructions = this.state.showQuestionInstruction && <QuestionInstructions 
        instructions={this.props.currentQuestion.instructions} 
        toggleQuestionInstructions={() => this.toggleQuestionInstructions()}
      /> 
    return (
      <div>
        {questionInstructions}
        {questionSequenceBody}
      </div>
    );
  }
}
