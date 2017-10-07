import React from 'react'
import PropTypes from 'prop-types';

export const Question = (props) => {
  return (
    <h3>{ props.question }</h3>
  );
};

Question.propTypes = {
  question: PropTypes.string
};

Question.defaultProps = {
  question: "Default Question"
};
