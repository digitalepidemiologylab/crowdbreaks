import React from 'react'
import wiggleSymbol from './wiggle.svg';
import normalSymbol from './normal.svg';
import zeroSymbol from './zero.svg';
import wiggleSymbolInactive from './wiggle-inactive.svg';
import normalSymbolInactive from './normal-inactive.svg';
import zeroSymbolInactive from './zero-inactive.svg';

export const VizOptions = (props) => {
  const imgPaths = {
    'wiggle': {
      'active': wiggleSymbol,
      'inactive': wiggleSymbolInactive
    },
    'normal': {
      'active': normalSymbol,
      'inactive': normalSymbolInactive
    },
    'zero': {
      'active': zeroSymbol,
      'inactive': zeroSymbolInactive
    }
  }


  let buttonOptions = {
    'zero': {
      img: imgPaths['zero']['inactive'],
      alt: 'zero',
      className: 'btn stream-graph-viz-option-btn'
    },
    'wiggle': {
      img: imgPaths['wiggle']['inactive'],
      alt: 'wiggle',
      className: 'btn stream-graph-viz-option-btn'
    },
    'normal': {
      img: imgPaths['normal']['inactive'],
      alt: 'normal',
      className: 'btn stream-graph-viz-option-btn'
    }
  };

  // active state
  buttonOptions[props.activeOption]['className'] += ' stream-graph-viz-option-btn-active';
  buttonOptions[props.activeOption]['img'] = imgPaths[props.activeOption]['active']

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
