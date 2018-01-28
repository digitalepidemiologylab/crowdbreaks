// React
import React from 'react'
import PropTypes from 'prop-types';
import { Line, defaults } from 'react-chartjs-2';
import { ButtonDropdown, DropdownItem, DropdownMenu, DropdownToggle} from 'reactstrap';

export class SentimentVisualization extends React.Component {
  constructor(props) {
    super(props);

    this.toggle = this.toggle.bind(this);
    this.state = {
      labels: [],
      all_data: [],
      pro_data: [],
      anti_data: [],
      neutral_data: [],
      start_date: props.start_date,
      end_date: props.end_date,
      dropdownOpen: false
    };

    this.options = {
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
            unit: 'day',
            displayFormats: {
              'day': 'YYYY-MM-DD'
            }
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

    defaults.global.defaultFontFamily = 'Roboto';
  }

  componentWillMount() {
    const data = {
      "api": {
        "interval": this.props.interval,
        "es_index_name": this.props.es_index_name,
        "start_date": this.props.start_date,
        "end_date": this.props.end_date
      }
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
        console.log(result)
        this.setState({
          labels: result.all_data.map((d) => new Date(d.key_as_string)),
          all_data: result.all_data.map((d) => d.doc_count),
          pro_data: result.pro_data.map((d) => d.doc_count),
          anti_data: result.anti_data.map((d) => d.doc_count),
          neutral_data: result.neutral_data.map((d) => d.doc_count)
        });
      }
    });
  }

  toggle() {
    this.setState({
      dropdownOpen: !this.state.dropdownOpen
    });
  }

  onSelect(interval) {
    const data = {
      "api": {
        "interval": interval,
        "es_index_name": this.props.es_index_name,
        "start_date": this.state.start_date,
        "end_date": this.state.end_date
      }
    };
    this.setData(data);
  }

  render() {
    const intervalOptions = ['hour', 'day'];
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
    var prevThis = this;

    return(
      <div>
        <ButtonDropdown isOpen={this.state.dropdownOpen} toggle={this.toggle} onSelect={(ev) => this.onSelect(ev)}>
          <DropdownToggle caret>
            Interval
          </DropdownToggle>
          <DropdownMenu>
            {intervalOptions.map(function(interval) {
              return <DropdownItem key={interval} onClick={() => prevThis.onSelect(interval)}>{interval}</DropdownItem>
            })}
          </DropdownMenu>
        </ButtonDropdown>
          
        <Line data={data} width={600} height={250} options={this.options} />
      </div>
    )
  }
}
