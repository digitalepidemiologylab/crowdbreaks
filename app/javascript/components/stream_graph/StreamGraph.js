// React
import React from 'react'
import { D3StreamGraph } from './D3StreamGraph';
import { VizOptions } from './VizOptions';
import { TimeOptions } from './TimeOptions';
import moment from 'moment';


export class StreamGraph extends React.Component {
  // Component was built with the concepts described in this blogpost: http://nicolashery.com/integrating-d3js-visualizations-in-a-react-app/
  // and: https://github.com/freddyrangel/playing-with-react-and-d3
  constructor(props) {
    super(props);
    let windowWidth = window.innerWidth;
    let width;
    let device = 'desktop';
    if (windowWidth < 576) {
      // mobile
      width = windowWidth - 40;
      device = 'mobile';
    } else if (windowWidth < 768) {
      // tablet
      width = 500;
      device = 'tablet';
    } else if (windowWidth < 992) {
      width = 560;
    } else if (windowWidth < 1200) {
      width = 760;
    } else {
      // desktop
      width = 910;
    }
    this.colors = ['#68AA43', '#FF9E4B', '#CD5050']; // green, orange, red
    this.keys = ['positive', 'neutral', 'negative'];
    this.keysToLegend = {'positive': 'Pro-vaccine', 'neutral': 'Neutral', 'negative': 'Anti-vaccine'}
    this.caption = "Real-time predictions of vaccination sentiment based on tweets in English language visualized as a stream graph.\
      No country-specific filtering has been applied.\
      Switch between temporal options (1 year, 3 month and 1 day) and representation options (area, wiggle, normalized) in order to explore the data."
    this.momentTimeFormat = 'YYYY-MM-DD HH:mm:ss'
    this.state = {
      isLoading: true,
      width: width,
      height: 300,
      activeVizOption: 'wiggle',
      errorNotification: '',
      useTransition: false,
      timeOption: '2',
      device: device,
      cachedData: {}
    };
  }

  componentDidMount() {
    const options = this.getTimeOption(this.state.timeOption)
    this.getData(options);
  }

  getTimeOption(option) {
    let interval, startDate, endDate;
    switch(option) {
      case '1':
        interval = 'day'
        endDate = moment.utc().startOf(interval)
        startDate = endDate.clone().subtract(1, 'year')
        break;
      case '2':
        interval = 'day'
        endDate = moment.utc().startOf(interval)
        startDate = endDate.clone().subtract(3, 'month')
        break;
      case '3':
        interval = 'hour'
        endDate = moment.utc().startOf(interval)
        startDate = endDate.clone().subtract(1, 'day')
        break;
    }
    // avoid first interval of endDate
    endDate.subtract(1, 'second')
    return {
      interval: interval,
      start_date: startDate.format(this.momentTimeFormat),
      end_date: endDate.format(this.momentTimeFormat),
      timeOption: option
    }
  }

  getData(options) {
    // check if data has been previously loaded
    if (options.timeOption in this.state.cachedData) {
      const newData = this.state.cachedData[options.timeOption];
      this.setState({
        data: newData,
        isLoading: false,
        useTransition: false,
        timeOption: options.timeOption
      });
      return
    }
    const params = {
      viz: {
        start_date: options.start_date,
        end_date: options.end_date,
        interval: options.interval
      }
    };
    $.ajax({
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      type: "POST",
      url: this.props.dataEndpoint,
      data: JSON.stringify(params),
      dataType: "json",
      contentType: "application/json",
      error: (result) => {
        this.setState({
          errorNotification: "Something went wrong when trying to load the data. Sorry ¯\\_(ツ)_/¯"
        })
        return
      },
      success: (result) => {
        console.log(result);
        const arrayLengths = this.keys.map((key) => result[key].length)
        const maxLengthKey = this.keys[arrayLengths.indexOf(Math.max(...arrayLengths))]
        let data = [];
        let counters = {};
        this.keys.forEach((key) => {
          counters[key] = 0;
        });

        for (let i=0; i < result[maxLengthKey].length; i++) {
          let d = {'date': new Date(moment.utc(result[maxLengthKey][i].key_as_string))}
          this.keys.forEach((key) => {
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
        this.keys.forEach((key) => {
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
        let cachedData = this.state.cachedData;
        cachedData[options.timeOption] = data;
        this.setState({
          data: data,
          isLoading: false,
          useTransition: false,
          timeOption: options.timeOption,
          cachedData: cachedData
        });
      }
    });
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

  onChangeVizOption(option) {
    this.setState({
      activeVizOption: option,
      useTransition: true
    });
  }

  onChangeTimeOption(option) {
    const options = this.getTimeOption(option)
    this.setState({
      isLoading: true
    })
    this.getData(options)
  }

  retrieveKeys(data) {
    let keys = [];
    if (this.state.data.length > 0) {
        keys = Object.keys(this.state.data[0]);
        keys = keys.filter(item => item !== 'date')
      }
    return keys;
  }

  render() {
    let body;
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
      let keys = this.retrieveKeys(this.state.data);
      body =
        <div>
          <div className='stream-graph-btn-group'>
            <TimeOptions
              timeOption={this.state.timeOption}
              onChangeOption={(e) => this.onChangeTimeOption(e)}
            />
              <VizOptions
                activeOption={this.state.activeVizOption}
                onChangeOption={(e) => this.onChangeVizOption(e)}
              />
          </div>
          <D3StreamGraph
            data={this.state.data}
            width={this.state.width}
            height={this.state.height}
            colors={this.colors}
            vizOption={this.state.activeVizOption}
            useTransition={this.state.useTransition}
            keys={keys}
            keysToLegend={this.keysToLegend}
            device={this.state.device}
          />
          <div className="mt-5 text-light">
            {this.caption}
          </div>
        </div>
    }

    return (
      <div id="stream-graph-container" ref={(container) => this.container = container}>
        {body}
      </div>
    )
  }
}
