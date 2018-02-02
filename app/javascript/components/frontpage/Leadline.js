// React
import React from 'react';

// Sub-components
import { LeadlineItem } from './LeadlineItem';

// Other
var moment = require('moment');

export class Leadline extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      queue_items: []
    };

    moment.locale(props.locale)
  }

  componentWillMount() {
    var postData = {
      'leadline': {
        'num_new_entries': '3',
        'exclude_usernames': [],
        'exclude_tweet_ids': [],
      }
    }
    this.getLeadline(postData)
  }

  getLeadline(postData) {
    $.ajax({
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      type: "POST",
      crossDomain: true,
      url: this.props.dataEndpoint,
      data: JSON.stringify(postData),
      dataType: "json",
      contentType: "application/json",
      success: (data) => {
        console.log(data)
        this.setState({
          queue_items: data
        });
      }
    });

  }

  render() {
    if (this.state.queue_items.length == 0) {
      return false;
    }

    var prevThis = this
    return(
      <div className="text-center">
        {this.state.queue_items.map(function(item) {
          return <LeadlineItem 
            key={item[3]}
            tweetId={item[0]}
            classified_by={item[1]}
            classified_as={item[2]}
            classified_at={moment(item[3]).fromNow()}
            project={item[4][prevThis.props.locale]}
            translations={prevThis.props.translations}
            projectsPath={prevThis.props.projectsPath}
            onTweetLoad={() => prevThis.onTweetLoad()}
          />
        })}
      </div>
    );
  }
}
