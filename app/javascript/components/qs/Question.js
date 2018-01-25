import React from 'react'
import PropTypes from 'prop-types';

export const Question = (props) => {
  return (
    <div>
      <h2 className='mb-5'>
        { props.question }
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
