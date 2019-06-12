import React from 'react'

export const LocalBatchCounts = (props) => {
  let content = null;
  if (props.testMode) {
    content = <p className='alert alert-info'>{props.translations.test_mode}</p>
      return wrapContent(content)
  }
  if (!props.noWorkAvailable) {
    let headerContent;
    if (props.userCount == 0) {
      headerContent= <p className='text-light'>{props.translations.welcome_user} {props.userName}! </p>;
    } else if (props.userCount == 1) {
      headerContent = <p className='text-light'>{props.translations.keep_going} {props.userCount.toLocaleString()} {props.translations.tweet_one}</p>;
    } else {
      headerContent = <p className='text-light'>{props.translations.keep_going} {props.userCount.toLocaleString()} {props.translations.tweet_other}</p>;
    }
    let totalText = props.translations.total_in_batch + ': ' + props.totalCount.toLocaleString()
    let statsUnavailableText = ""
    if (!props.tweetTextAvailable) {
      statsUnavailableText = props.translations.total_unavailable + ': ' + props.totalCountUnavailable.toLocaleString();
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
