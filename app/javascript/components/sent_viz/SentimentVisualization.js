// React
import React from 'react'
import PropTypes from 'prop-types';
import { Line, defaults } from 'react-chartjs-2';
import { DropdownButton, MenuItem } from 'react-bootstrap';

export class SentimentVisualization extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      labels: [],
      all_data: [],
      pro_data: [],
      anti_data: [],
      neutral_data: [],
      interval: props.interval
    };

    this.options = {
      scales: {
        yAxes: [{
          scaleLabel: {
            display: true,
            labelString: "Counts"
          }
        }]
      },
      elements: {
        line: {
          tension: 0,
          fill: false
        }
      }
    };

    defaults.global.defaultFontFamily = 'Noto Sans';
  }

  componentWillMount() {
    const data = {
      "interval": this.props.interval
    };
    this.setData(data);
  }

  onSelect(ev) {
    const data = {
      "interval": ev
    };
    this.setData(data);
  }

  setData(data) {
    $.ajax({
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      type: "POST",
      crossDomain: true,
      url: this.props.updateVisualizationPath,
      data: JSON.stringify(data),
      dataType: "json",
      contentType: "application/json",
      success: (result) => {
        this.setState({
          labels: result.all_data.map((d) => d.key_as_string),
          all_data: result.all_data.map((d) => d.doc_count),
          pro_data: result.pro_data.map((d) => d.doc_count),
          anti_data: result.anti_data.map((d) => d.doc_count),
          neutral_data: result.neutral_data.map((d) => d.doc_count)
        });
      }
    });
  }

  render() {
    const intervalOptions = ['Hour', 'Day'];
    const data = {
      labels: this.state.labels,
      datasets: [
        {
          label: 'All',
          data: this.state.all_data
        },
        {
          label: 'Pro-vaccine',
          borderColor: '#2ecc71',
          backgroundColor: '#2ecc71',
          data: this.state.pro_data
        },
        {
          label: 'Anti-vaccine',
          borderColor: '#e74c3c',
          backgroundColor: '#e74c3c',
          data: this.state.anti_data
        },
        {
          label: 'Neutral',
          borderColor: '#b5b5b5',
          backgroundColor: '#b5b5b5',
          data: this.state.neutral_data
        }
      ]
    };

    return(
      <div>
        <div className="pull-right">
          <DropdownButton bsSize='small' onSelect={(ev) => this.onSelect(ev)} pullRight={true} title="Interval" id="nav-dropdown">
            {intervalOptions.map(function(interval) {
              return <MenuItem href="#" key={interval} eventKey={interval.toLowerCase()}>{interval}</MenuItem>
            })}
          </DropdownButton>
        </div>
          
        <Line data={data} width={600} height={250} options={this.options} />
      </div>
    )
  }
}
