// React
import React from 'react'
import PropTypes from 'prop-types';
import ReactCSSTransitionGroup from 'react-addons-css-transition-group';
import { ClipLoader } from 'react-spinners';

// Other 
var humps = require('humps');

// Sub-components
import { Answer } from './../components/Answer';
import { Question } from './../components/Question';
import { TweetEmbedding } from './../components/TweetEmbedding';
import { Final } from './../components/Final';

// Styling for this component: app/assets/stylesheets/qs_container_component.scss

export class QSContainer extends React.Component {
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
    // submit answer asynchronously
    var resultData = humps.decamelizeKeys({
      result: {
        answerId: answerId,
        questionId: this.state.currentQuestion.id,
        userId: this.props.userId,
        tweetId: this.props.tweetId,
        projectId: this.props.projectId
      }
    });
    
    $.ajax({
      type: "POST",
      url: this.props.resultsPath,
      data: resultData,
    });
    
    // find next question
    var nextQuestion = this.nextQuestion(this.state.currentQuestion.id, answerId);
    if (nextQuestion === null) {
      this.setState({
        'questionSequenceHasEnded': true,
        'tweetHasLoaded': false
      });
    } else {
      // Go to next question
      this.setState({
        'currentQuestion': this.props.questions[nextQuestion]
      });
    }
  }

  onNextQuestionSequence() {
    // simply reload page to get new question sequence
    window.location.reload(false);
  }

  onTweetLoad() {
    this.setState({
      'tweetIsLoading': false
    });
  }

  render() {
    let questionSequenceBody = null

    if (!this.state.questionSequenceHasEnded) {
      let parentThis = this;
      questionSequenceBody = <div>
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

    } else {
      questionSequenceBody = <Final 
        onNextQuestionSequence={() => this.onNextQuestionSequence()}
        projectsPath={this.props.projectsPath}
        translations={this.props.translations}
      />
    }
    return (
      <div id='question-answer-container' className='col-md-8 col-md-offset-2'>
        {questionSequenceBody}
      </div>
    );
  }
}

QSContainer.propTypes = {
  initialQuestionId: PropTypes.number,
  questions: PropTypes.object,
  transitions: PropTypes.object,
  tweetId: PropTypes.string,
  projectsPath: PropTypes.string,
  resultsPath: PropTypes.string,
  translations: PropTypes.object,
  userId: PropTypes.number,
  projectId: PropTypes.number
};