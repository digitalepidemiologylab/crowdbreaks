import React from 'react'
import PropTypes from 'prop-types';

export const ExampleInput = (props) => {
  return (
    <button onClick={props.onExampleClick} className='btn btn-block btn-secondary'>
      { props.exampleText }
    </button>
  );
};

ExampleInput.propTypes = {
  exampleText: PropTypes.string,
  onExampleClick: PropTypes.func
};
