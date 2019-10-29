import React from 'react'
import wiggleSymbol from './wiggle.svg';
import normalSymbol from './normal.svg';
import zeroSymbol from './zero.svg';

export const VizOptions = (props) => {
  let buttonOptions = {
    'zero': {
      img: zeroSymbol,
      alt: 'zero',
      className: 'btn stream-graph-viz-option-btn'
    },
    'wiggle': {
      img: wiggleSymbol,
      alt: 'wiggle',
      className: 'btn stream-graph-viz-option-btn'
    },
    'normal': {
      img: normalSymbol,
      alt: 'normal',
      className: 'btn stream-graph-viz-option-btn'
    }
  };

  // active state
  buttonOptions[props.activeOption]['className'] += ' stream-graph-viz-option-btn-active';

  // generate buttons
  let buttons = Object.keys(buttonOptions).map((k, idx) => {
    return <button className={buttonOptions[k].className}
      onClick={() => props.onChangeOption(k)}
      key={k}>
      <img src={buttonOptions[k].img} alt={buttonOptions[k].alt}/>
    </button>
  })

  return (
    <div className="btn-group stream-graph-viz-options-container">
      {buttons}
    </div>
  );
};
