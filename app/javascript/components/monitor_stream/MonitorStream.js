// React
import React from 'react'
import PropTypes from 'prop-types';
import { Bar, defaults } from 'react-chartjs-2';
import { DropdownButton, MenuItem } from 'react-bootstrap';
var moment = require('moment');


export class MonitorStream extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      data: [],
      past_minutes: props.past_minutes,
      min: moment().subtract(props.past_minutes, 'minutes').format('YYYY-MM-DD HH:mm'),
      max: moment().format('YYYY-MM-DD HH:mm')
    };

    this.intervalId = null;
    this.aggregation_interval = '10s';

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
          }
        }],
        xAxes: [{
          type: 'time',
          barPercentage: .8,
          time: {
            unit: 'second',
            displayFormats: {
              'second': 'HH:mm:ss'
            },
            min: this.state.min,
            max: this.state.max
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
    defaults.global.defaultFontFamily = 'Noto Sans';
  }

  componentWillMount() {
    const data = {
      'api': {
        'es_index_name': this.props.es_index_name,
        'interval': this.aggregation_interval,
        'past_minutes': this.state.past_minutes
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
        'interval': this.aggregation_interval,
        'past_minutes': this.state.past_minutes
      }
    }
    this.getData(data);
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
          labels: result.map((d) => moment.utc(d.key_as_string, 'YYYY-MM-DD HH:mm:ss')),
          counts: result.map((d) => d.doc_count),
          min: moment().subtract(this.props.past_minutes, 'minutes').add(1, 'minute').format('YYYY-MM-DD HH:mm'),
          max: moment().add(1, 'minute').format('YYYY-MM-DD HH:mm')
        });
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
          backgroundColor: '#2574a9'
        }
      ]
    };
    this.options.scales.xAxes[0].time.min = this.state.min;
    this.options.scales.xAxes[0].time.max = this.state.max;

    return(
      <div>
        <Bar key={Date()} data={data} height={150} options={this.options} />
      </div>
    )
  }
}
