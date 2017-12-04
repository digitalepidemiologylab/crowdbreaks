import React from 'react'
import PropTypes from 'prop-types';

export const ExampleInput = (props) => {
  return (
    <button onClick={props.onExampleClick} className='btn-md btn-block btn-default'>
      { props.exampleText }
    </button>
  );
};

ExampleInput.propTypes = {
  exampleText: PropTypes.string,
  onExampleClick: PropTypes.func
};
