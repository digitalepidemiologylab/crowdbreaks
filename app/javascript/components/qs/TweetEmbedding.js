import React from 'react'
import PropTypes from 'prop-types';
import { Tweet } from 'react-twitter-widgets'
import TweetEmbed from 'react-tweet-embed'

export const TweetEmbedding = (props) => {
  var options = {
    cards: 'hidden',
    conversation: 'none',
    marginBottom: '0px'
  };
  return (
    <div className="row justify-content-center">
      <Tweet 
        tweetId={props.tweetId} 
        options={options}
        onLoad={props.onTweetLoad}
      />
      <TweetEmbed
        id={props.tweetId} 
        options={options}
        onTweetLoadSuccess={props.onTweetLoad}
      />
    </div>
  );
};

TweetEmbedding.propTypes = {
  tweetId: PropTypes.string,
  onTweetLoad: PropTypes.func
};
