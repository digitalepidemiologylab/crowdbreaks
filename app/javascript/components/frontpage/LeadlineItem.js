import React from 'react';

import TweetEmbed from 'react-tweet-embed'
import OvalPositive from './oval-positive.svg'
import OvalNegative from './oval-negative.svg'
import OvalNeutral from './oval-neutral.svg'

export class LeadlineItem extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
    };

    this.options = {
      cards: 'hidden',
      conversation: 'none'
    };

    this.imageDict = {
      'pro-vaccine': OvalPositive,
      'anti-vaccine': OvalNegative,
      'neutral': OvalNeutral
    };
  }

  onTweetLoad() {
    // Slightly hackish way to change CSS within shadow dom
    let style = document.createElement( 'style' )
    style.innerHTML = '.EmbeddedTweet { border-color: #ced7de; max-width: 100%; }'
    try {
      let shadowRoot = this.tweet.querySelector('.twitter-tweet').shadowRoot
      if (shadowRoot != null) {
        shadowRoot.appendChild(style)
      } 
    } catch(err) {
      console.log('An error occured while trying to access shadow DOM.')
      console.log(err)
    }
  }

  render() {
    return (
      <div className="classification" ref={ (tweet) => {this.tweet = tweet} } >
        <TweetEmbed
          id={this.props.tweetId} 
          options={this.options}
          onTweetLoadSuccess={() => this.onTweetLoad()}
        />
        <div className="classification-info">
          <p className="small text-light">

            {this.props.translations.by}&nbsp;{this.props.classified_by}&nbsp;{this.props.translations.classified}&nbsp;·&nbsp;{this.props.classified_at}<br/>
            {this.props.translations.in_project}&nbsp;<a href={this.props.projectsPath}>{this.props.project}</a>
            {/* {this.props.translations.classified_as}&nbsp;<span className="badge badge-sentiment"><img src={this.imageDict[this.props.classified_as]} />&nbsp;{this.props.classified_as}&nbsp;</span>&nbsp;{this.props.translations.by}&nbsp;{this.props.classified_by}&nbsp;·&nbsp;{this.props.classified_at}<br/> */}
            {/* {this.props.translations.in_project}&nbsp;<a href={this.props.projectsPath}>{this.props.project}</a> */}
          </p>
        </div>
      </div>
    );
  }
};
