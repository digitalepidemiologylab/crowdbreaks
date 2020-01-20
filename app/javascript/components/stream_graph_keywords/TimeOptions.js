import React from 'react'

export const TimeOptions = (props) => {
  const defaultClass = 'btn stream-graph-time-option-btn'
  let buttonOptions = {
    1: {
      alt: 'year',
      className: defaultClass,
      text: '1m'
    },
    2: {
      alt: 'month',
      className: defaultClass,
      text: '7d'
    },
    3: {
      alt: 'day',
      className: defaultClass,
      text: '1d'
    },
  };

  // active state
  buttonOptions[props.timeOption]['className'] += ' stream-graph-time-option-btn-active';

  // generate buttons
  let buttons = Object.keys(buttonOptions).map((k, idx) => {
    return <button className={buttonOptions[k].className}
      onClick={() => props.onChangeOption(k)}
      alt={buttonOptions[k].alt}
      key={k}>
        {buttonOptions[k].text}
    </button>
  })

  return (
    <div className="btn-group stream-graph-keywords-time-options-container">
      {buttons}
    </div>
  );
};
