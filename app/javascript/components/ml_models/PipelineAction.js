import React from 'react';

export const PipelineAction = (props) => {
  let checkbox, body;
  if (props.status == 'InService') {
    if (props.activeEndpoint) {
      checkbox = <input type='checkbox' defaultChecked={props.activeEndpoint} onClick={() => props.onUpdateAction('deactivate_endpoint', props.modelName, props.projectName)}/>
    } else {
      checkbox = <input type='checkbox' defaultChecked={props.activeEndpoint} onClick={() => props.onUpdateAction('activate_endpoint', props.modelName, props.projectName)}/>
    }
    body = <label className='switch'>
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
