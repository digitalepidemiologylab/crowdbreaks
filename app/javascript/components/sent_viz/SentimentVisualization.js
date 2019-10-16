// React
import React from 'react'
import { Line, defaults } from 'react-chartjs-2';
import { Input, Col, Row, FormText } from 'reactstrap';

export class SentimentVisualization extends React.Component {
  constructor(props) {
    super(props);

    this.toggle = this.toggle.bind(this);
    this.default_point_radius = 1.5;
    this.default_border_width = 3;
    this.state = {
      labels: [],
      all_data: [],
      pro_data: [],
      anti_data: [],
      neutral_data: [],
      avg_sentiment: [],
      avg_sentiment_smoothed: [],
      start_date: this.props.start_date,
      end_date: this.props.end_date,
      dropdownOpen: false,
      interval: this.props.interval,
      point_radius: this.default_point_radius,
      border_width: this.default_border_width,
      includeRetweets: props.include_retweets
    };

    this.options = {
      scales: {
        yAxes: [
          {
            id: "counts",
            scaleLabel: {
              display: true,
              labelString: "Counts"
            },
            ticks: {
              min: 0
            }
          },{
            id: "sentiment_index",
            position: "right",
            scaleLabel: {
              display: true,
              labelString: "Sentiment index"
            },
            ticks: {
              suggestedMin: -0.2
            },
            gridLines: {
              display: false
            }
          }
        ],
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
          fill: false,
        }
      }
    };

    defaults.global.defaultFontFamily = 'Roboto';
  }

  componentDidMount() {
    const data = {
      "viz": {
        "interval": this.props.interval,
        "es_index_name": this.props.es_index_name,
        "start_date": this.props.start_date,
        "end_date": this.props.end_date,
        "include_retweets": this.props.include_retweets
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
        this.setState({
          labels: result.all_data.map((d) => new Date(d.key_as_string)),
          all_data: result.all_data.map((d) => d.doc_count),
          pro_data: result.pro_data.map((d) => d.doc_count),
          anti_data: result.anti_data.map((d) => d.doc_count),
          neutral_data: result.neutral_data.map((d) => d.doc_count),
          avg_sentiment: result.avg_sentiment.map((d) => d.avg_sentiment.value),
          avg_sentiment_smoothed: result.avg_sentiment.map((d) => d.avg_sentiment.value_smoothed)
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
    const data = {
      "viz": {
        "interval": this.state.interval,
        "es_index_name": this.props.es_index_name,
        "start_date": this.state.start_date,
        "end_date": this.state.end_date,
        "include_retweets": this.state.includeRetweets
      }
    };
    this.changePlotFormatting();
    this.setData(data);
  }

  changePlotFormatting() {
    let point_radius, border_width;
    switch (this.state.interval) {
      case '1h': // Fallthrough
      case '2h':
        point_radius = 1
        border_width = 1.5
        break;
      case '3h':
        point_radius = 1.5
        border_width = 2
        break;
      default:
        point_radius = this.default_point_radius
        border_width = this.default_border_width
    }
    this.setState({
      point_radius: point_radius,
      border_width: border_width
    });
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

  onCheckboxToggle() {
    this.setState({
      includeRetweets: !this.state.includeRetweets
    });
  }

  render() {
    const intervalOptions = ['1h', '2h', '3h', '6h', '12h', '24h'];
    const data = {
      labels: this.state.labels,
      datasets: [
        {
          label: 'All',
          yAxisID: 'counts',
          data: this.state.all_data,
          spanGaps: true,
          pointRadius: this.state.point_radius,
          borderWidth: this.state.border_width
        },
        {
          label: 'Pro-vaccine',
          yAxisID: 'counts',
          borderColor: '#5bb12a',
          backgroundColor: '#5bb12a',
          data: this.state.pro_data,
          spanGaps: true,
          pointRadius: this.state.point_radius,
          borderWidth: this.state.border_width
        },
        {
          label: 'Anti-vaccine',
          yAxisID: 'counts',
          borderColor: '#db4457',
          backgroundColor: '#db4457',
          data: this.state.anti_data,
          spanGaps: true,
          pointRadius: this.state.point_radius,
          borderWidth: this.state.border_width
        },
        {
          label: 'Neutral',
          yAxisID: 'counts',
          borderColor: '#1e9CeA',
          backgroundColor: '#1e9CeA',
          data: this.state.neutral_data,
          spanGaps: true,
          pointRadius: this.state.point_radius,
          borderWidth: this.state.border_width
        },
        {
          label: 'Sentiment index',
          yAxisID: 'sentiment_index',
          borderColor: '#657786',
          backgroundColor: '#657786',
          data: this.state.avg_sentiment,
          spanGaps: true,
          pointRadius: 1,
          showLine: false,
        },
        {
          label: 'Sentiment index (loess fit)',
          yAxisID: 'sentiment_index',
          borderColor: '#657786',
          backgroundColor: '#657786',
          data: this.state.avg_sentiment_smoothed,
          spanGaps: true,
          borderWidth: 4,
          pointRadius: 0
        }
      ]
    };
    return(
      <div>
        <Row className="mb-4">
          <Col>
            <Row>
              <Col xs="12" md="3">
                <div className="form-group">
                  <label className="label-form-control">Start</label>
                  <Input type="text" name="start_date" onChange={(ev) => this.handleChangeStart(ev)} value={this.state.start_date}/>
                  <FormText color="muted">Format: YYYY-MM-dd HH:mm:ss</FormText>
                </div>
              </Col>
              <Col xs="12" md="3">
                <div className="form-group">
                  <label className="label-form-control">End</label>
                  <Input type="text" name="end_date" onChange={(ev) => this.handleChangeEnd(ev)} value={this.state.end_date}/>
                  <FormText color="muted">Format: YYYY-MM-dd HH:mm:ss</FormText>
                </div>
              </Col>
              <Col xs="12" md="3">
                <div className="form-group">
                  <label className="label-form-control">Interval</label>
                  <Input type="select" name="interval" defaultValue={this.state.interval} onChange={(ev) => this.onSelect(ev)}>
                    {intervalOptions.map(function(interval) {
                      return <option key={interval}>{interval}</option>
                    })}
                  </Input>
                </div>
              </Col>
              <Col xs="12" md="3">
                <div className="form-group">
                  <label className="label-form-control">
                    Include retweets
                    <Input className="ml-2" type="checkbox" defaultValue={this.state.includeRetweets} onChange={() => this.onCheckboxToggle()}/>
                  </label>
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
