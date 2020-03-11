import React from 'react';

export const PipelineAction = (props) => {
  let checkbox, body, actionName;
  if (props.status == 'InService') {
    if (props.activeEndpoint) {
      actionName = 'deactivate_endpoint'
    } else {
      actionName = 'activate_endpoint'
    }
    checkbox = <input type='checkbox' checked={props.activeEndpoint} onChange={() => props.onUpdateAction(actionName)}/>
    body = <label className='switch' style={{marginBottom: '0px'}}>
      {checkbox}
      <span className='slider round'></span>
      <span className='switch-label'></span>
    </label>
  }
  return (
    <div>
      {body}
    </div>
  );
};
