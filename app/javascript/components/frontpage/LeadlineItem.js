import React from 'react';

import { Tweet } from 'react-twitter-widgets'
import OvalPositive from './oval-positive.svg'
import OvalNegative from './oval-negative.svg'
import OvalNeutral from './oval-neutral.svg'

export const LeadlineItem = (props) => {
  const options = {
    cards: 'hidden',
    conversation: 'none'
  };
  const imageDict = {
    'pro-vaccine': OvalPositive,
    'anti-vaccine': OvalNegative,
    'neutral': OvalNeutral
  };
  return (
    <div className="classification">
      <div className="tweet-example">
        <Tweet 
          tweetId={props.tweetId} 
          options={options}
        />
      </div>
      <div className="classification-info">
        <p className="small text-light">
          {props.translations.classified_as}&nbsp;<span className="badge badge-sentiment"><img src={imageDict[props.classified_as]} />&nbsp;{props.classified_as}&nbsp;</span>&nbsp;{props.translations.by}&nbsp;{props.classified_by}&nbsp;·&nbsp;{props.classified_at}<br/>
          {props.translations.in_project}&nbsp;<a href={props.projectsPath}>{props.project}</a>
        </p>
      </div>
    </div>
  );
};
