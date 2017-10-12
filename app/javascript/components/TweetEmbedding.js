import React from 'react'
import PropTypes from 'prop-types';
import { Tweet  } from 'react-twitter-widgets'

export const TweetEmbedding = (props) => {
  var options = {
    cards: 'hidden',
    conversation: 'none'
  return (
    <Tweet 
      tweetId={props.tweetId} 
      options={options}
    />
  );
};

TweetEmbedding.propTypes = {
  tweetId: PropTypes.string
  };
};
