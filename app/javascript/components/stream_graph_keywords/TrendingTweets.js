// React
import React from 'react';

// Sub-components
import TweetEmbed from 'react-tweet-embed'

export const TrendingTweets = (props) => {
  const options = {
    cards: 'hidden',
    conversation: 'none'
  };

  let body;
  if (props.trendingTweets.length > 0) {
    body = props.trendingTweets.map(function(item, idx) {
      return <div className='trending-tweet' key={idx}>
        <TweetEmbed
        id={item}
        key={idx}
        options={options}
        onTweetLoadSuccess={() => props.onTrendingTweetLoad(idx)}
        />
      </div>
    });
  } else if (props.error) {
    body = <div className="alert alert-primary">Couldn't load trending content. Sorry ¯\\_(ツ)_/¯</div>
  } else {
    body = <div className="alert alert-primary">No results for these keywords.</div>
  }
  let loader = props.isLoading && <div className='row justify-content-center'>
    <div className="col-12">
      <div className="spinner" style={{margin: 'auto'}}></div>
    </div>
  </div>

  return (
    <div>
      <h4 className="and-divider mb-4 mt-5">
        <span>Trending</span>
      </h4>
      <div className="trending-tweets-container">
        {body}
        {loader}
      </div>
    </div>
  );
}
