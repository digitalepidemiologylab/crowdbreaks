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
      'tweetIsLoading': true
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
      if (nextQuestion === null) {
        // End of question sequence
        this.setState({
          'tweetHasLoaded': false
        });
        this.props.onQuestionSequenceEnd();
      } else {
        // Go to next question
        this.setState({
          'currentQuestion': this.props.questions[nextQuestion]
        });
      }
    }
  }

  onTweetLoad() {
    if (document.getElementById('twitter-widget-0').shadowRoot.children.length != 3) {
      // Note to future me: Improve this, quite hacky, possibly use innerHTML=="" instead
      // Todo: Language change does not work, wait for twitter-widget-0 to be available
      // Tweet is not available anymore, handle error in parent
      this.props.onTweetLoadError();
    } 

    this.setState({
      'tweetIsLoading': false
    });
  }

  render() {
    let parentThis = this;
    let questionSequenceBody = <div>
      <TweetEmbedding 
        tweetId={this.props.tweetId}
        onTweetLoad={() => parentThis.onTweetLoad()}
      />
      { this.state.tweetIsLoading &&
          <div className="clip-loader">
            <ClipLoader
              color={'#444'} 
            />
          </div> }
          { !this.state.tweetIsLoading && <div>
            <div className="question">
              <Question question={this.state.currentQuestion.question}/>
            </div>
            <div className="answers">
              <span>
                {this.state.currentQuestion.answers.map(function(answer) {
                  return <Answer 
                    key={answer.id} 
                    answer={answer.answer} 
                    submit={() => parentThis.onSubmitAnswer(answer.id)}
                    color={answer.color}
                  />
                })}
              </span>
            </div>
          </div> }
        </div>

    return (
      <div id='question-answer-container' className='col-md-8 col-md-offset-2'>
        {questionSequenceBody}
      </div>
    );
  }
}

QuestionSequence.propTypes = {
  initialQuestionId: PropTypes.number,
  questions: PropTypes.object,
  transitions: PropTypes.object,
  tweetId: PropTypes.string,
  userId: PropTypes.number,
  projectId: PropTypes.number,
  postData: PropTypes.func,
  onTweetLoadError: PropTypes.func,
  onQuestionSequenceEnd: PropTypes.func
};
