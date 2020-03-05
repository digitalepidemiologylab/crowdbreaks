import React from 'react'

export const Actions = (props) => {
  let body;
  if (props.isLoadingActions) {
    body = <div className="spinner-small mt-1" ></div>
  } else {
    if (props.status !== 'InService') {
      body = <a onClick={() => props.onUpdateAction('delete_model', props.modelName, props.projectName)} style={{cursor:'pointer'}}>
        <i className='fa fa-trash'></i>
      </a>
    }
  }
  return (
    <div>
      {body}
    </div>
  );
};
