import React from 'react'
import PropTypes from 'prop-types';

export const Answer = (props) => {
  return (
    <button onClick={ props.submit } className='btn'>{ props.answer }</button>
  );
};

Answer.propTypes = {
  answer: PropTypes.string,
  submit: PropTypes.func
};

Answer.defaultProps = {
  answer: "Default answer"
};
