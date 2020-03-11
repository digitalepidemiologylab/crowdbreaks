import React from 'react'

export const PrimaryEndpoint = (props) => {
  let body;
  if (props.isLoadingPrimaryEndpoint) {
    body = <div className="spinner-small mt-1" ></div>
  } else {
    if (props.activeEndpoint) {
      if (props.isPrimaryEndpoint) {
        body = <div className='badge badge-success'>Yes</div>
      } else {
        body = <button className='btn btn-link-no-pad' onClick={() => props.onUpdateAction('make_primary')}>Make primary</button>
      }
    }
  }
  return (
    <div>
      {body}
    </div>
  );
};
