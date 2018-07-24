import React from 'react'
import PropTypes from 'prop-types';

export const Question = (props) => {
  let instructionsSymbol;
  let buttonStyle = {border: 0, padding: 0, cursor: 'pointer'}
  if (props.hasInstructions) {
    instructionsSymbol = <button
      style={buttonStyle}
      onClick={props.toggleQuestionInstructions}>
      <sup>&ensp;<i className='fa fa-question-circle' style={{color: '#212529'}}></i></sup>
    </button>

  }
  return (
    <div>
      <h2 className='mb-5'>
        { props.question }
        { instructionsSymbol }
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
