import React from 'react'
import PropTypes from 'prop-types';
import { Answer } from './../components/Answer';
import { Question } from './../components/Question';
import { TweetEmbedding } from './../components/TweetEmbedding';

export class QSContainer extends React.Component {
  constructor(props) {
    super(props);

    // set initial question state
    var initialQuestion = props.questions[props.initialQuestionId];
    this.state = {
      'currentQuestion': initialQuestion.question,
      'currentAnswers': initialQuestion.possible_answers
    }
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
    var nextQuestion = this.nextQuestion(this.state.currentQuestion.id, answerId);
    if (nextQuestion === null) {
      console.log('End of question sequence!')
    } else {
      // Go to next question
      this.setState({
        'currentQuestion': this.props.questions[nextQuestion].question,
        'currentAnswers': this.props.questions[nextQuestion].possible_answers
      });
    }
  }

  render() {
    var parentThis = this;
    return (
      <div id='question-answer-container' className='col-md-8 col-md-offset-2'>
        <TweetEmbedding tweetId={this.props.tweetId}/>
        <div id='question' className="question">
          <Question question={this.state.currentQuestion.question_translations.en}/>
        </div>
        <div className="answers">
          <span>
            {this.state.currentAnswers.map(function(answer) {
              return <Answer 
                key={answer.id} 
                answer={answer.answer_translations.en} 
                submit={() => parentThis.onSubmitAnswer(answer.id)}
                />
            })}
          </span>
        </div>
      </div>
    );
  }
}

QSContainer.propTypes = {
  questions: PropTypes.object,
  initialQuestionID: PropTypes.string,
  transitions: PropTypes.object,
  tweetId: PropTypes.string
};
