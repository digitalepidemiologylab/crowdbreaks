// React
import React from 'react'
import { D3StreamGraph } from './D3StreamGraphKeywords';
import { TimeOptions } from './TimeOptions';
import { TrendingTweets } from './TrendingTweets';
import moment from 'moment';


export class StreamGraphKeywords extends React.Component {
  // Component was built with the concepts described in this blogpost: http://nicolashery.com/integrating-d3js-visualizations-in-a-react-app/
  // and: https://github.com/freddyrangel/playing-with-react-and-d3
  constructor(props) {
    super(props);
    let windowWidth = window.innerWidth;
    let width, device, numTrendingTopics;
    if (windowWidth < 576) {
      // mobile
      device = 'mobile';
      width = windowWidth - 40;
      numTrendingTopics = 5;
    } else if (windowWidth < 768) {
      // tablets
      device = 'tablet';
      width = 500;
      numTrendingTopics = 5;
    } else if (windowWidth < 992) {
      device = 'tablet';
      width = 560;
      numTrendingTopics = 5;
    } else if (windowWidth < 1200) {
      device = 'tablet';
      width = 760;
      numTrendingTopics = 8;
    } else {
      // desktop
      device = 'desktop';
      width = 910;
      numTrendingTopics = 10;
    }
    this.activeVizOption = 'zero';
    this.baseColor = '#1e9CeA'
    this.queryColor = '#FF9E4B'
    this.defaultKey = '__other'
    this.caption = "Real-time keyword Twitter stream for all content which matches at least one of the keywords \"ncov\", \"wuhan\", \"coronavirus\", \"covid\", or \"sars-cov-2\". Tracking started January 13, 2020. Y-axis shows counts per hour (for the '1m' option counts are per day)."
    this.momentTimeFormat = 'YYYY-MM-DDTHH:mm:ss'
    this.numTrendingTweets = 10;
    this.numTrendingTopics = numTrendingTopics;
    let timeOption = props.timeOption;
    if (!timeOption) {
      timeOption = '2'
    }
    let query = props.query;
    if (!query) {
      query = '';
    }
    this.state = {
      isLoading: true,
      isLoadingQuery: false,
      isLoadingTrendingTweets: true,
      isLoadingTrendingTweetsByIndex: [],
      isLoadingTrendingTopics: true,
      trendingTweets: [],
      trendingTweetsError: false,
      trendingTopics: [],
      trendingTopicsError: false,
      width: width,
      height: 300,
      errorNotification: '',
      useTransition: false,
      timeOption: timeOption,
      device: device,
      cachedData: {},
      query: query,
      queryTyped: query,
      keys: [],
      colors: [],
    };
  }

  getKeys() {
    if (this.state.query.length) {
      return [this.state.query]
    }
    return [this.defaultKey]
  }

  setKeysColors() {
    this.setState({
      keys: this.getKeys(),
      colors: this.getColors()
    })
  }

  getColors() {
    if (this.state.query.length) {
      return [this.queryColor]
    }
    return [this.baseColor]
  }

  componentDidMount() {
    // viz data
    const options = this.getTimeOption(this.state.timeOption)
    this.getData(options);
    // trending tweets
    this.getTrendingTweets();
    // trending topics
    this.getTrendingTopics();
  }

  getTimeOption(option) {
    let interval, startDate, endDate;
    switch(option) {
      case '1':
        interval = 'day';
        endDate = 'now';
        startDate = 'now-1M';
        break;
      case '2':
        interval = 'hour';
        endDate = 'now';
        startDate = 'now-2w';
        break;
      case '3':
        interval = 'hour';
        endDate = 'now';
        startDate = 'now-1d';
        break;
    }
    return {
      interval: interval,
      start_date: startDate,
      end_date: endDate,
      timeOption: option,
      es_index_name: this.props.esIndexName,
      query: this.state.query
    }
  }

  getData(options) {
    // check if data has been previously loaded
    if (options.timeOption+this.state.query in this.state.cachedData) {
      const newData = this.state.cachedData[options.timeOption+this.state.query];
      this.setState({
        data: newData,
        isLoading: false,
        isLoadingQuery: false,
        useTransition: false,
        timeOption: options.timeOption
      }, this.setKeysColors());
      return
    }
    const params = {
      viz: options
    };
    $.ajax({
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      type: "POST",
      crossDomain: true,
      url: this.props.dataEndpoint,
      data: JSON.stringify(params),
      dataType: "json",
      contentType: "application/json",
      error: (result) => {
        this.setState({
          errorNotification: "Something went wrong when trying to load the data. Sorry ¯\\_(ツ)_/¯"
        })
      },
      success: (result) => {
        const keys = this.getKeys()
        const arrayLengths = keys.map((key) => result[key].length)
        const maxLengthKey = keys[arrayLengths.indexOf(Math.max(...arrayLengths))]
        let data = [];
        let counters = {};
        keys.forEach((key) => {
          counters[key] = 0;
        });

        for (let i=0; i < result[maxLengthKey].length; i++) {
          let d = {'date': new Date(moment.utc(result[maxLengthKey][i].key_as_string))}
          keys.forEach((key) => {
            if (result[key][counters[key]] && result[key][counters[key]].key_as_string === result[maxLengthKey][i].key_as_string) {
              let doc_count = result[key][counters[key]].doc_count;
              if (doc_count === 'null') {
                d[key] = 0;
              } else {
                d[key] = doc_count;
              }
              counters[key] += 1;
            } else {
              d[key] = 0;
            }
          });
          data.push(d);
        }
        if (data.length == 0) {
          this.setState({
            errorNotification: "Something went wrong when trying to load the data. Sorry ¯\\_(ツ)_/¯"
          })
          return
        }
        // pad data with zeroes in the beginning and end of the range (if data is missing)
        const startDaterange = this.daterange(moment.utc(options.start_date), moment(data[0].date), options.interval);
        let padZeroes = {}
        keys.forEach((key) => {
          padZeroes[key] = 0;
        })
        for (let i=startDaterange.length-1; i >= 0; i--) {
          const d = {date: startDaterange[i], ...padZeroes}
          data.unshift(d)
        }
        const endDaterange = this.daterange(moment(data.slice(-1)[0].date), moment.utc(options.end_date).subtract(1, options.interval), options.interval);

        for (let i=0; i < endDaterange.length; i++) {
          const d = {date: endDaterange[i], ...padZeroes}
          data.push(d)
        }
        // add "all" counts
        for (let i=0; i < data.length; i++) {
          let sum = 0;
          keys.forEach((key) => {
            sum += data[i][key];
          })
          data[i]['all'] = sum;
        }

        // add to cached data
        let cachedData = this.state.cachedData;
        cachedData[options.timeOption + this.state.query] = data;

        this.setState({
          data: data,
          isLoading: false,
          isLoadingQuery: false,
          useTransition: false,
          timeOption: options.timeOption,
          cachedData: cachedData,
        }, this.setKeysColors());
      }
    });
  }

  getTrendingTweets() {
    let postData = {
      'viz': {
        'num_trending_tweets': this.numTrendingTweets,
        'es_index_name': this.props.esIndexName,
        'query': this.state.query
      }
    }
    $.ajax({
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      type: "POST",
      url: this.props.dataEndpointTrendingTweets,
      data: JSON.stringify(postData),
      dataType: "json",
      contentType: "application/json",
      success: (data) => {
        let loadingByIndex = new Array(data.length).fill(true);
        if (data.length > 0 && Array.isArray(data)) {
          this.setState({
            trendingTweets: data,
            isLoadingTrendingTweetsByIndex: loadingByIndex
          });
        } else {
          this.setState({
            isLoadingTrendingTweets: false
          });
        }
      },
      error: (response) => {
        this.setState({
          isLoadingTrendingTweets: false,
          trendingTweetsError: true
        });
      }
    });
  }

  getTrendingTopics() {
    let postData = {
      'viz': {
        'num_trending_topics': this.numTrendingTopics,
        'es_index_name': this.props.esIndexName
      }
    }
    $.ajax({
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      type: "POST",
      url: this.props.dataEndpointTrendingTopics,
      data: JSON.stringify(postData),
      dataType: "json",
      contentType: "application/json",
      success: (data) => {
        if (data.length > 0) {
          this.setState({
            trendingTopics: data,
            isLoadingTrendingTopics: false
          });
        } else {
          this.setState({
            isLoadingTrendingTopics: false
          });
        }
      },
      error: (response) => {
        this.setState({
          isLoadingTrendingTopics: false,
          trendingTweetsError: true
        });
      }
    });
  }

  onTrendingTweetLoad(idx) {
    let loadingByIndex = this.state.isLoadingTrendingTweetsByIndex;
    loadingByIndex[idx] = false;
    this.setState({
      isLoadingTrendingTweetsByIndex: loadingByIndex,
      isLoadingTrendingTweets: !loadingByIndex.every((s) => s == false)
    })
  }

  daterange(startDate, stopDate, frequency='hour') {
    var dateArray = [];
    var currentDate = startDate;
    while (currentDate < stopDate) {
      dateArray.push(new Date(currentDate))
      currentDate = moment(currentDate).add(1, frequency);
    }
    return dateArray;
  }

  onChangeTimeOption(option) {
    const options = this.getTimeOption(option)
    this.setState({
      isLoading: true
    })
    this.getData(options)
    this.setParam('t', options['timeOption'])
  }

  onChangeQueryField(e) {
    this.setState({
      'queryTyped': e.target.value
    })
  }

  onSearchSubmit(queryTyped) {
    this.setState({
      'query': queryTyped,
      'queryTyped': queryTyped,
      'isLoadingQuery': true,
      'isLoadingTrendingTweets': true,
      'isLoadingTrendingTweetsByIndex': [],
      'trendingTweets': [],
      'trendingTweetsError': false
    }, () => {
      const options = this.getTimeOption(this.state.timeOption)
      this.getData(options);
      this.getTrendingTweets();
      this.setParam('q', this.state.query)
    })
  }

  setParam(key, value) {
    if (history.pushState) {
      let searchParams = new URLSearchParams(window.location.search);
      searchParams.set(key, value);
      let newurl = window.location.protocol + "//" + window.location.host + window.location.pathname + '?' + searchParams.toString();
      window.history.pushState({path: newurl}, '', newurl);
    }
  }

  onKeyDownQueryField(e) {
    if (e.keyCode === 13) {
      this.onSearchSubmit(this.state.queryTyped)
    }
  }

  onTrendingTopicClick(item) {
    this.onSearchSubmit(item)
  }


  render() {
    let body, optionBtnGroup, searchBtn, trendingTopics;
    if (this.state.isLoadingQuery) {
      searchBtn = <div className="spinner-small sg-search-query-btn" style={{"marginRight": "12px", "marginLeft": "12px"}}></div>
    } else {
      searchBtn = 'Search'
    }
    let searchbar = <div className="sg-search-query">
      <div className="sg-search-query-form-group">
        <input value={this.state.queryTyped} placeholder="Search for a keyword..." type="search" className="form-control"  onKeyDown={(e) => this.onKeyDownQueryField(e)} onChange={(e) => this.onChangeQueryField(e)}></input>
      </div>
      <button className='btn btn-primary sg-search-query-btn' onClick={() => this.onSearchSubmit(this.state.queryTyped)}>{searchBtn}</button>
    </div>
    if (this.state.isLoading) {
      if (this.state.errorNotification == '') {
        body =
          <div className='loading-notification-container'>
            <div className="loading-notification">
              <div className="spinner spinner-with-text"></div>
              <div className='spinner-text'>Loading...</div>
            </div>
          </div>
      } else {
        body = <div className='loading-notification-container'>
          <div className="alert alert-primary">
              {this.state.errorNotification}
          </div>
        </div>
      }
    } else {
      optionBtnGroup = <div className='stream-graph-keywords-btn-group'>
        <TimeOptions timeOption={this.state.timeOption} onChangeOption={(e) => this.onChangeTimeOption(e)} />
      </div>
      body =
        <div>
          {optionBtnGroup}
          <D3StreamGraph
            data={this.state.data}
            width={this.state.width}
            height={this.state.height}
            colors={this.state.colors}
            vizOption={this.activeVizOption}
            useTransition={this.state.useTransition}
            queryColor={this.queryColor}
            keys={this.state.keys}
            device={this.state.device}
            query={this.state.query}
          />
          <div className="mt-4 text-light">
            {this.caption}
          </div>
          <TrendingTweets
            trendingTweets={this.state.trendingTweets}
            onTrendingTweetLoad={(idx) => this.onTrendingTweetLoad(idx)}
            error={this.state.trendingTweetsError}
            isLoading={this.state.isLoadingTrendingTweets}
          />
        </div>
    }

    const prevThis = this;
    trendingTopics = !this.state.trendingTopicsError && !this.state.isLoadingTrendingTopics && this.state.trendingTopics.length > 0 && <div className='trending-topics-container'>
      <span>Text tokens trending now:</span>
      <span className="trending-topics">
        {this.state.trendingTopics.map((item, i) => {
          return <button className='btn btn-link trending-topic' onClick={() => prevThis.onTrendingTopicClick(item)} key={i}>{item}</button>
        })}
      </span>
    </div>

    return (
      <div id="stream-keyword-graph-container" ref={(container) => this.container = container}>
        {searchbar}
        {trendingTopics}
        {body}
      </div>
    )
  }
}
