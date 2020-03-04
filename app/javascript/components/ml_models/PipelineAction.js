import React from 'react';

export const PipelineAction = (props) => {
  let checkbox, body, actionName;
  if (props.status == 'InService') {
    if (props.activeEndpoint) {
      actionName = 'deactivate_endpoint'
    } else {
      actionName = 'activate_endpoint'
    }
    checkbox = <input type='checkbox' checked={props.activeEndpoint} onChange={() => props.onUpdateAction(actionName, props.modelName, props.projectName)}/>
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
