// React
import React from 'react'
import PropTypes from 'prop-types';
import { Line, defaults } from 'react-chartjs-2';
import { Input, Col, Row, FormText } from 'reactstrap';

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
      start_date: this.props.start_date,
      end_date: this.props.end_date,
      dropdownOpen: false,
      interval: this.props.interval
    };

    this.options = {
      scales: {
        yAxes: [{
          scaleLabel: {
            display: true,
            labelString: "Counts"
          },
          ticks: {
            min: 0
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
      "viz": {
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

  onSelect(event) {
    this.setState({
      interval: event.target.value
    })
  }

  refresh() {
    var data = {
      "viz": {
        "interval": this.state.interval,
        "es_index_name": this.props.es_index_name,
        "start_date": this.state.start_date,
        "end_date": this.state.end_date
      }
    };
    this.setData(data);
  }

  handleChangeStart(event) {
    this.setState({
      start_date: event.target.value
    })
  }

  handleChangeEnd(event) {
    this.setState({
      end_date: event.target.value
    })
  }

  render() {
    const intervalOptions = ['hour', 'day'];
    var data = {
      labels: this.state.labels,
      datasets: [
        {
          label: 'All',
          data: this.state.all_data
        },
        {
          label: 'Pro-vaccine',
          borderColor: '#5bb12a',
          backgroundColor: '#5bb12a',
          data: this.state.pro_data
        },
        {
          label: 'Anti-vaccine',
          borderColor: '#db4457',
          backgroundColor: '#db4457',
          data: this.state.anti_data
        },
        {
          label: 'Neutral',
          borderColor: '#1e9CeA',
          backgroundColor: '#1e9CeA',
          data: this.state.neutral_data
        }
      ]
    };
    var prevThis = this;

    return(
      <div>
        <Row className="mb-4">
          <Col>
            <Row>
              <Col xs="12" md="4">
                <div className="form-group">
                  <label className="label-form-control">Start</label>
                  <Input type="text" name="start_date" onChange={(ev) => this.handleChangeStart(ev)} value={this.state.start_date}/>
                  <FormText color="muted">Format: YYYY-MM-dd HH:mm:ss</FormText>
                </div>
              </Col>
              <Col xs="12" md="4">
                <div className="form-group">
                  <label className="label-form-control">End</label>
                  <Input type="text" name="end_date" onChange={(ev) => this.handleChangeEnd(ev)} value={this.state.end_date}/>
                  <FormText color="muted">Format: YYYY-MM-dd HH:mm:ss</FormText>
                </div>
              </Col>
              <Col xs="12" md="4">
                <div className="form-group">
                  <label className="label-form-control">Interval</label>
                  <Input type="select" name="interval" defaultValue={this.state.interval} onChange={(ev) => this.onSelect(ev)}>
                    {intervalOptions.map(function(interval) {
                      return <option key={interval}>{interval}</option>
                    })}
                  </Input>
                </div>
              </Col>
            </Row>
            <button className="btn btn-primary" onClick={() => this.refresh()}>Refresh</button>
          </Col>
        </Row>

        <Row>
          <Col>
            <Line data={data} width={600} height={250} options={this.options} />
          </Col>
        </Row>
      </div>
    )
  }
}
