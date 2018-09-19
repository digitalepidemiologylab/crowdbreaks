import React from 'react'
import PropTypes from 'prop-types';


export const TweetTextEmbedding = (props) => {
  return (
    <div className="question-sequence-fake-tweet">
      {props.tweetText}
    </div>
  );
};

TweetTextEmbedding.propTypes = {
  tweetText: PropTypes.string,
};
