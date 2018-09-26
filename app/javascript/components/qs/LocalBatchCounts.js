import React from 'react'
import PropTypes from 'prop-types';


export const LocalBatchCounts = (props) => {
  let content = null;
  if (props.testMode) {
    content = <p className='alert alert-info'>You are running in test mode. No results are recorded. Tweets shown are randomly selected from your batch.</p> 
      return wrapContent(content)
  }
  if (!props.noWorkAvailable) {
    let headerContent;
    if (props.userCount == 0) {
      headerContent= <p className='text-light'>Welcome {props.userName}! You haven't completed any work in this batch yet.</p>;
    } else if (props.userCount == 1) {
      headerContent = <p className='text-light'>Keep going! You have finished {props.userCount} tweet.</p>;
    } else {
      headerContent = <p className='text-light'>Keep going! You have finished {props.userCount} tweets.</p>;
    }
    let totalText = "Total in this batch: " + props.totalCount
    let statsUnavailableText = ""
    if (!props.tweetTextAvailable) {
      statsUnavailableText = "Total unavailable: " + props.totalCountUnavailable;
    }
    content = <div>
      {headerContent}
      <div className='text-light'>{totalText}<br/>{statsUnavailableText}</div>
    </div>
  }
  return wrapContent(content)
}

function wrapContent(content) {
  return (
    <div className="row justify-content-center">
      <div className="col-md-8">
        {content}
      </div>
    </div>
  )
}
