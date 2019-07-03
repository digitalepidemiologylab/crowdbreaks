import React from 'react'
import PropTypes from 'prop-types';
import TweetEmbed from 'react-tweet-embed'

export const TweetEmbedding = (props) => {
  let options = {};
  if (!props.tweetDisplayMode || props.tweetDisplayMode == 'hide_card_hide_conversation') {
    options = {
      cards: 'hidden',
      conversation: 'none',
    };
  } else if (props.tweetDisplayMode == 'show_card_hide_conversation') {
    options = {
      conversation: 'none'
    };
  } else if (props.tweetDisplayMode == 'hide_card_show_conversation') {
    options = {
      cards: 'hidden'
    };
  }
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
