// React
import React from 'react'
import PropTypes from 'prop-types';
import ReactCSSTransitionGroup from 'react-addons-css-transition-group';
import { ClipLoader } from 'react-spinners';

// Other 
var humps = require('humps');

// Sub-components
import { Answer } from './Answer';
import { Question } from './Question';
import { TweetEmbedding } from './TweetEmbedding';

// Styling for this component: app/assets/stylesheets/qs_container_component.scss

export class QuestionSequence extends React.Component {
  constructor(props) {
    super(props);

    // set initial question state
    this.state = {
      'currentQuestion': props.questions[props.initialQuestionId],
      'questionSequenceHasEnded': false,
      'tweetIsLoading': true,
      'numQuestionsAnswered': 0
    };
  }

  nextQuestion(currentQuestionId, answerId) {
    // case no transitions from current question Id -> end of question sequence
    if (!(currentQuestionId in this.props.transitions)) {
      return null;
    }

    var possible_transitions = this.props.transitions[currentQuestionId];
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
    for (var i=0; i < possible_transitions.length; i++) {
      if(possible_transitions[i].answer == answerId) {
        return possible_transitions[i].to_question;
      }
    }
    // no transitions were found
    return null;
  }

  onSubmitAnswer(answerId) {
    // collect result data
    var resultData = humps.decamelizeKeys({
      result: {
        answerId: answerId,
        questionId: this.state.currentQuestion.id,
        userId: this.props.userId,
        tweetId: this.props.tweetId,
        projectId: this.props.projectId
      }
    });

    // Make POST request in parent component
    var status = this.props.postData(resultData);
    if (status) {
      // find next question
      var nextQuestion = this.nextQuestion(this.state.currentQuestion.id, answerId);
      var newNumQuestionAnswered = this.state.numQuestionsAnswered + 1;
      if (nextQuestion === null) {
        // End of question sequence
        this.setState({
          'tweetHasLoaded': false,
          'numQuestionsAnswered': newNumQuestionAnswered
        });
        this.props.onQuestionSequenceEnd();
      } else {
        // Go to next question
        this.setState({
          'currentQuestion': this.props.questions[nextQuestion],
          'numQuestionsAnswered': newNumQuestionAnswered
        });
      }
    }
  }

  onTweetLoad() {
    var style = document.createElement( 'style'  )
    style.innerHTML = '.EmbeddedTweet { border-color: #ced7de; max-width: 100%; }'
    try {
      var shadowRoot = this.tweet.querySelector('.twitter-tweet').shadowRoot
      if (shadowRoot != null) {
        shadowRoot.appendChild(style)
      }
    } catch(err) {
      console.log('An error occured while trying to access shadow DOM.')
    }
    this.setState({
      'tweetIsLoading': false
    });
  }

  render() {
    let parentThis = this;
    let progressDots = []
    let Q = "Q" + (this.state.numQuestionsAnswered+1).toString()
    for (let i = 0; i < this.props.numTransitions; ++i) {
      let liClassName = "";
      if (i < this.state.numQuestionsAnswered) {
        liClassName = "complete"
      } else if (i == this.state.numQuestionsAnswered) {
        liClassName = "current"
      }
      progressDots.push(
        <li className={liClassName} key={i}><span>{i}</span></li>
      )
    }
    let questionSequenceBody = <div ref={(tweet) => this.tweet = tweet}>
      {/* Title and tweet */}
      <div className='row justify-content-center'> 
        <div className="col-12">
          <h4 className="mb-5">{this.props.projectTitle}</h4>
          <TweetEmbedding 
            tweetId={this.props.tweetId}
            onTweetLoad={() => parentThis.onTweetLoad()}
          />
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
            <div className="col-12 col-lg-8 text-center">
              <div className="v-line"></div>
              <h4 className="circle-text mb-4">{Q}</h4>
              {/* Question */}
              <Question question={this.state.currentQuestion.question}/>
              {/* Answers */}
              <div className="buttons mb-4">
                {this.state.currentQuestion.answers.map(function(answer) {
                  return <Answer 
                    key={answer.id} 
                    answer={answer.answer} 
                    submit={() => parentThis.onSubmitAnswer(answer.id)}
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
    </div>

    return (
      <div>
        {questionSequenceBody}
      </div>
    );
  }
}

QuestionSequence.propTypes = {
  projectTitle: PropTypes.string,
  initialQuestionId: PropTypes.number,
  questions: PropTypes.object,
  transitions: PropTypes.object,
  tweetId: PropTypes.string,
  userId: PropTypes.number,
  projectId: PropTypes.number,
  postData: PropTypes.func,
  onTweetLoadError: PropTypes.func,
  onQuestionSequenceEnd: PropTypes.func,
  numTransitions: PropTypes.number
};
