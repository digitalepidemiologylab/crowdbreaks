import React from 'react'
import PropTypes from 'prop-types';

export const Answer = (props) => {
  var buttonStyle = {};
  var btnClassName = 'btn btn-lg';
  const predefinedBtnTypes = ['btn-primary', 'btn-secondary', 'btn-positive', 'btn-negative'];
  if (predefinedBtnTypes.includes(props.color)) {
    btnClassName += ' '+props.color;
  } else {
    buttonStyle.backgroundColor = props.color;
  }
  return (
    <button 
      key={ props.answer }
      onClick={ props.submit }
      style={ buttonStyle }
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
