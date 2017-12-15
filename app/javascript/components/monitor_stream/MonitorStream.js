// React
import React from 'react'
import PropTypes from 'prop-types';
import { Bar, defaults } from 'react-chartjs-2';
import { DropdownButton, MenuItem } from 'react-bootstrap';

export class MonitorStream extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      data: []
    };

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
          time: {
            unit: 'minute',
            displayFormats: {
              'day': 'YYYY-MM-DD',
              'minute': 'HH:mm'
            }
          }
        }]
      },
      elements: {
        rectangle: {
          borderSkipped: 'left'
        }
      }
    };

    defaults.global.defaultFontFamily = 'Noto Sans';
  }

  componentWillMount() {
    const data = {
      'api': {
        'es_index_name': this.props.es_index_name,
        'interval': 'hour'
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
        console.log(result);
        this.setState({
          labels: result.map((d) => new Date(d.key_as_string)),
          counts: result.map((d) => d.doc_count)
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

    return(
      <Bar data={data} height={150} options={this.options} />
    )
  }
}
