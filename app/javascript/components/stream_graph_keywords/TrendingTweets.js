// React
import React from 'react';

// Sub-components
import TweetEmbed from 'react-tweet-embed'

export class TrendingTweets extends React.Component {
  constructor(props) {
    super(props);

    this.options = {
      cards: 'hidden',
      conversation: 'none'
    };
    this.state = {
      items: [],
      loaded: false,
      loadedByIndex: [],
      error: false
    };
  }

  componentDidMount() {
    let postData = {
      'viz': {
        'num_trending_tweets': this.props.numTrendingTweets,
        'project_slug': this.props.projectSlug
      }
    }
    this.getTrendingTweets(postData)
  }

  getTrendingTweets(postData) {
    $.ajax({
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      type: "POST",
      url: this.props.dataEndpointTrendingTweets,
      data: JSON.stringify(postData),
      dataType: "json",
      contentType: "application/json",
      success: (data) => {
        let loadedByIndex = new Array(data.length).fill(false);
        if (data.length > 0) {
          this.setState({
            items: data,
            loadedByIndex: loadedByIndex
          });
        } else {
          this.setState({
            loaded: true
          });
        }
      },
      error: (response) => {
        this.setState({
          loaded: true,
          error: true
        });
      }
    });

  }

  onTweetLoad(idx) {
    let loadedByIndex = this.state.loadedByIndex;
    loadedByIndex[idx] = true;
    this.setState({
      loadedByIndex: loadedByIndex,
      loaded: loadedByIndex.every((s) => s == true)
    })
  }

  render() {
    const prevThis = this;
    let tweets = this.state.items.map(function(item, idx) {
          return <div className='trending-tweet' key={idx}>
            <TweetEmbed
              id={item}
              key={idx}
              options={prevThis.options}
              onTweetLoadSuccess={() => prevThis.onTweetLoad(idx)}
            />
          </div>
        });
    let body = <div>
      {tweets}
      {!this.state.loaded &&
        <div className='row justify-content-center'>
          <div className="col-12">
            <div className="spinner" style={{margin: 'auto'}}></div>
          </div>
        </div>
      }
    </div>;
    let error = this.state.error && <div className="alert alert-primary">Couldn't load trending content. Sorry ¯\\_(ツ)_/¯</div>
    return(
      <div className="trending-tweets-container">
        <h4 className="and-divider mb-5 mt-5">
          <span>Trending</span>
        </h4>
        {body}
        {error}
      </div>
    );
  }
}
