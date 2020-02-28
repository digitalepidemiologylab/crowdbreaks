import React from 'react'

import Running from './running.svg'
import NotRunning from './not-running.svg'
import Paused from './paused.svg'

export const EndpointStatus = (props) => {
  let icon;
  let body = <span></span>
  if (props.status) {
    if (props.status == 'InService') {
      icon = Running;
    } else if (props.status == 'Failed' || props.status == 'OutOfService') {
      icon = NotRunning;
    } else {
      icon = Paused;
    }
    body = <span className='badge badge-sentiment'>
      <img src={icon} alt=""/>
      &nbsp;
      {props.status}
    </span>
  }

  return (
    <div>
      {body}
    </div>
  );
};
