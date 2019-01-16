import React from 'react'
import PropTypes from 'prop-types';
import Markdown from 'react-markdown';


export const Instructions = (props) => {
  const markdownStyle = {textAlign: 'left', border: '1px solid #ced7de', borderRadius: '2px', padding: '20px'}
  let symbol = props.display ? 'fa fa-minus' : 'fa fa-plus'

  let buttonTitle = props.display ? props.translations.hide_instructions : props.translations.show_instructions
  let button = <button 
    onClick={props.onToggleDisplay} 
    className='btn btn-secondary btn-lg btn-block'>
    <i className={symbol} style={{color: '#212529'}}></i>&emsp;{buttonTitle}
  </button>

  return(
    <div className="row justify-content-center mb-3">
      <div className="col-md-8">
        {button}
        {props.display && <div style={markdownStyle}>
          <Markdown source={props.instructions} />
        </div>}
      </div>
    </div>
  )
}
