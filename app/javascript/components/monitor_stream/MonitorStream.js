// React
import React from 'react'
import { Bar, defaults } from 'react-chartjs-2';
let moment = require('moment');

defaults.global.defaultFontFamily = "'Roboto', sans-serif";
defaults.global.defaultFontColor = '#333';

export class MonitorStream extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      data: [],
      min: moment().utc().subtract(props.past_minutes, 'minutes').format('YYYY-MM-DD HH:mm'),
      max: moment().utc().format('YYYY-MM-DD HH:mm')
    };

    this.intervalId = null;

    this.options = {
      maintainAspectRatio: false,
      title: {
        display: true,
        text: props.project_name,
        fontSize: 23,
        position: 'top',
        fontStyle: 'normal',
        fontColor: '#333333'
      },
      legend: {
        display: false
      },
      scales: {
        yAxes: [{
          scaleLabel: {
            display: true,
            labelString: "Counts"
          },
          ticks: {
            min: 0,
            maxTicksLimit: 3
          }
        }],
        xAxes: [{
          type: 'time',
          time: {
            unit: 'second',
            displayFormats: {
              'second': 'HH:mm:ss'
            }
          },
          ticks: {
            min: this.state.min,
            max: this.state.max,
            display: true,
            autoSkip: true,
            maxTicksLimit: this.props.past_minutes * 60 / 10
          }
        }]
      },
      elements: {
        rectangle: {
          borderSkipped: 'left'
        }
      },
      animation: false
    };
  }

  componentDidMount() {
    const data = {
      'api': {
        'es_index_name': this.props.es_index_name,
        'interval': this.props.aggregation_interval,
        'past_minutes': this.props.past_minutes,
        'round_to_sec': this.props.round_to_sec
      }
    }
    this.getData(data);

    // Automatic update
    if (this.props.auto_update) {
      this.intervalId = setInterval(() => this.triggerGetData(), 2000);
    }
  }

  componentWillUnmount() {
    if (this.props.auto_update) {
      clearInterval(this.intervalId);
    }
  }

  triggerGetData() {
    const data = {
      'api': {
        'es_index_name': this.props.es_index_name,
        'interval': this.props.aggregation_interval,
        'past_minutes': this.props.past_minutes,
        'round_to_sec': this.props.round_to_sec
      }
    }
    this.getData(data);
  }

  roundToSeconds(datetime, seconds) {
    const remainder = seconds - (moment.seconds() % seconds);
    datetime = datetime.add(remainder, 'seconds');
    return datetime
  }

  getData(data) {
    $.ajax({
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      type: "GET",
      crossDomain: true,
      url: this.props.data_endpoint,
      data: data,
      dataType: "json",
      contentType: "application/json",
      success: (result) => {
        this.setState({
          labels: result.map((d) => moment.utc(d.from_as_string).format('YYYY-MM-DD HH:mm:ss')),
          counts: result.map((d) => d.doc_count),
          min: moment().utc().subtract(this.props.past_minutes, 'minutes').add(1, 'minute').format('YYYY-MM-DD HH:mm'),
          max: moment().utc().add(1, 'minute').format('YYYY-MM-DD HH:mm')
        });
        // console.log('success');
        // console.log(this.state.labels);
        // console.log(this.state.counts);
      }
    });
  }

  render() {
    const data = {
      labels: this.state.labels,
      datasets: [
        {
          label: this.props.project_name,
          data: this.state.counts,
          backgroundColor: '#1e9CeA',
          barPercentage: 10
        }
      ]
    };
    console.log('data');
    console.log(data);
    this.options.scales.xAxes[0].ticks.min = this.state.min;
    this.options.scales.xAxes[0].ticks.max = this.state.max;

    return(
      <div>
        <Bar key={Date()} data={data} height={150} options={this.options} />
      </div>
    )
  }
}
