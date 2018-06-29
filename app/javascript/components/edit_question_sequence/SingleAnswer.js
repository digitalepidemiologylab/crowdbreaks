import React from 'react'

export const SingleAnswer = (props) => {
  var buttonStyle = {};
  var btnClassName = 'btn btn-lg';
  const predefinedBtnTypes = ['btn-primary', 'btn-secondary', 'btn-positive', 'btn-negative'];
  if (predefinedBtnTypes.includes(props.color)) {
    btnClassName += ' '+props.color;
  } else {
    buttonStyle.backgroundColor = props.colorOptions[props.color];
  }
  return (
    <button 
      style={ buttonStyle }
      className={ btnClassName }>{ props.answer }
    </button>
  );
};
