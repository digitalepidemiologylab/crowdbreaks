import React from 'react'
import PropTypes from 'prop-types';
import { Tweet  } from 'react-twitter-widgets'

export const TweetEmbedding = (props) => {
  return (
    <Tweet tweetId={props.tweetId} />
  );
};

TweetEmbedding.propTypes = {
  tweetId: PropTypes.string
};
