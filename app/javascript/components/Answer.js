import React from 'react'
import PropTypes from 'prop-types';

export const Answer = (props) => {
  var buttonStyle = {
    backgroundColor: props.color
  };
  return (
    <button 
      style={buttonStyle}
      onClick={ props.submit }
      className='btn'>{ props.answer }
    </button>
  );
};

Answer.propTypes = {
  answer: PropTypes.string,
  submit: PropTypes.func,
  color: PropTypes.string
};
