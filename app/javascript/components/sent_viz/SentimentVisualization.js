// React
import React from 'react'
import PropTypes from 'prop-types';
import {Line, defaults} from 'react-chartjs-2';

export class SentimentVisualization extends React.Component {
  constructor(props) {
    super(props);
    var all_data_labels = props.all_data.map((d) => d.key_as_string);
    var all_data_counts = props.all_data.map((d) => d.doc_count);
    var pro_data_counts = props.pro_data.map((d) => d.doc_count);
    var anti_data_counts = props.anti_data.map((d) => d.doc_count);
    var neutral_data_counts = props.neutral_data.map((d) => d.doc_count);

    this.options = {
      scales: {
        yAxes: [{
          scaleLabel: {
            display: true,
            labelString: "Counts"
          }
        }]
      }
    };

    defaults.global.defaultFontFamily = 'Noto Sans';

    this.data = {
      labels: all_data_labels,
      datasets: [
        {
          label: 'All',
          fill: false,
          lineTension: 0.0,
          data: all_data_counts
        },
        {
          label: 'Pro-vaccine',
          fill: false,
          borderColor: '#2ecc71',
          backgroundColor: '#2ecc71',
          lineTension: 0.0,
          data: pro_data_counts
        },
        {
          label: 'Anti-vaccine',
          fill: false,
          borderColor: '#e74c3c',
          backgroundColor: '#e74c3c',
          lineTension: 0.0,
          data: anti_data_counts
        },
        {
          label: 'Neutral',
          fill: false,
          borderColor: '#b5b5b5',
          backgroundColor: '#b5b5b5',
          lineTension: 0.0,
          data: neutral_data_counts
        }
      ]
    };
  }

  render() {
    return(
      <div>
        <Line data={this.data} width={600} height={250} options={this.options} />
      </div>
    )
  }
}
