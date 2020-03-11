import React from 'react'

export const EndpointAction = (props) => {
  let body;
  if (props.isLoadingEndpointAction) {
    body = <div className="spinner-small mt-1" ></div>
  } else if (!props.status) {
    body = <button className='btn btn-link-no-pad' onClick={() => props.onUpdateAction('create_endpoint')}>Create endpoint</button>
  } else if (props.status == 'InService' && !props.activeEndpoint) {
    body = <button className='btn btn-link-no-pad' onClick={() => props.onUpdateAction('delete_endpoint')}>Delete endpoint</button>
  }
  return (
    <div>
      {body}
    </div>
  );
};
