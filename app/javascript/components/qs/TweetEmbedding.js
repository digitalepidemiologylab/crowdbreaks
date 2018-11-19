import React from 'react'
import PropTypes from 'prop-types';
import TweetEmbed from 'react-tweet-embed'

export const TweetEmbedding = (props) => {
  const options = {
    cards: 'hidden',
    conversation: 'none'
  };
  return (
    <div className="question-sequence-tweet">
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
