import React from 'react'
import PropTypes from 'prop-types';

export const Answer = (props) => {
  let buttonStyle = {};
  let btnClassName = 'btn btn-lg';
  const predefinedBtnTypes = ['btn-primary', 'btn-secondary', 'btn-positive', 'btn-negative'];
  if (predefinedBtnTypes.includes(props.color)) {
    btnClassName += ' '+props.color;
  } else {
    buttonStyle.backgroundColor = props.colorOptions[props.color];
  }
  return (
    <button
      key={ props.answer }
      onClick={ props.submit }
      style={ buttonStyle }
      disabled={ props.disabled }
      accessKey={ props.accessKey }
      className={ btnClassName }>{ props.answer }
    </button>
  );
};

Answer.propTypes = {
  answer: PropTypes.string,
  submit: PropTypes.func,
  onSubmitCallback: PropTypes.func,
  color: PropTypes.string,
};
