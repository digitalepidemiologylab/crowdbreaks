import React from 'react'
import PropTypes from 'prop-types';

export const Question = (props) => {
  let instructionBtn, question, question_first, question_last, question_split;
  let buttonStyle = {border: 0, padding: 0, cursor: 'pointer'}
  if (props.hasInstructions) {
    instructionBtn = <button
      style={buttonStyle}
      onClick={props.toggleQuestionInstructions}>
      <i className='fa fa-question-circle' style={{color: '#212529'}}></i>
    </button>

    question_split = props.question.split(' ');
    if (question_split.length > 1) {
      question_first = question_split.slice(0, question_split.length-1).join(' ')
      question_last = question_split[question_split.length-1]
      question = <div>{question_first}&nbsp;<span className='no-wrap'>{question_last}&nbsp;<sup>{instructionBtn}</sup></span></div>
    } else {
      question = <div className="no-split">{props.question}&nbsp;<sup>{instructionBtn}</sup></div>
    }
  } else {
    question = props.question;
  }

  return (
    <div>
      <h2 className='mb-5'>
        {question}
      </h2>
    </div>
  );
};

Question.propTypes = {
  question: PropTypes.string
};

Question.defaultProps = {
  question: "Default Question"
};
