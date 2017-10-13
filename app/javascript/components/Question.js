import React from 'react'
import PropTypes from 'prop-types';
import ReactCSSTransitionGroup from 'react-addons-css-transition-group';

export const Question = (props) => {
  const transitionOptions = {
    transitionName: "fade",
    transitionEnterTimeout: 700,
    transitionLeaveTimeout: 0
  };
  return (
    <ReactCSSTransitionGroup {...transitionOptions}>
      <div key={props.question}>{ props.question }</div>
    </ReactCSSTransitionGroup>
  );
};

Question.propTypes = {
  question: PropTypes.string
};

Question.defaultProps = {
  question: "Default Question"
};
