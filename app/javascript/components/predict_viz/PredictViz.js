// React
import React from 'react'
import { Line, defaults } from 'react-chartjs-2';
import moment from 'moment';

defaults.global.defaultFontFamily = "'Roboto', sans-serif";
defaults.global.defaultFontColor = '#333';

export class PredictViz extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      data: {},
      average_label_vals: [],
      startDate: 'now-3M',
      endDate: 'now',
      dropdownOpen: false,
      includeRetweets: true,
      isLoadingEndpointInfo: true,
      isLoadingPredictions: true,
      predictionsError: false,
      predictionsErrorNotification: '',
      project: '',
      questionTag: '',
      runName: '',
      endpointsFound: false,
      labels: [],
      interval: '24h',
      timeAxis: [],
      minIndexVal: -1,
      maxIndexVal: 1
    };
    this.state['startDateValue'] = this.state.startDate;
    this.state['endDateValue'] = this.state.endDate;
    this.state['intervalValue'] = this.state.interval;
    this.intervalOptions = ['1h', '2h', '3h', '6h', '12h', '24h', '3d', '7d'];
  }

  componentDidMount() {
    document.addEventListener('keydown', (e) => this.onPressEnter(e), false);
    this.init();
  }

  componentWillUnmount() {
    document.removeEventListener('keydown', this.onPressEnter, false);
  }

  onPressEnter(e) {
    if (e.keyCode == 13) {
      this.refresh();
    }
  }

  getPredictions() {
    const data = {
      viz: {
        start_date: this.state.startDate,
        end_date: this.state.endDate,
        es_index_name: this.state.project,
        run_name: this.state.runName,
        include_retweets: this.state.includeRetweets,
        interval: this.state.interval,
        question_tag: this.state.questionTag,
        answer_tags: this.state.labels,
        average_label_val: true,
        use_cache: false
      }
    }
    $.ajax({
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      type: "POST",
      url: this.props.getPredictionsPath,
      dataType: "json",
      data: JSON.stringify(data),
      contentType: "application/json",
      success: (resp) => {
        console.log(resp);
        const predictions = resp['predictions']
        const avg = resp['avg_label_vals']
        if (predictions.length == 0) {
          this.renderPredictionError('No data available')
          return
        }
        const arrayLengths = this.state.labels.map((label) => predictions[label].length)
        const maxLengthKey = this.state.labels[arrayLengths.indexOf(Math.max(...arrayLengths))]
        let data = [];
        let counters = {};
        this.state.labels.forEach((label) => {
          counters[label] = 0;
        });
        for (let i=0; i < predictions[maxLengthKey].length; i++) {
          const currentDate = predictions[maxLengthKey][i].key_as_string;
          let d = {'date': new Date(moment.utc(currentDate))}
          this.state.labels.forEach((label) => {
            if (predictions[label][counters[label]] && predictions[label][counters[label]].key_as_string === currentDate) {
              let doc_count = predictions[label][counters[label]].doc_count;
              if (doc_count === 'null') {
                d[label] = 0;
              } else {
                d[label] = doc_count;
              }
              counters[label] += 1;
            } else {
              d[label] = 0;
            }
          });
          // fetch label val data
          if (avg[i].key_as_string == currentDate) {
            if ('mean_label_val' in avg[i]) {
              d['avg_label_val'] = avg[i]['mean_label_val']['value']
            } else {
              d['avg_label_val'] = null;
            }
            if ('mean_label_val_moving_average' in avg[i]) {
              d['avg_label_val_moving_average'] = avg[i]['mean_label_val_moving_average']['value']
            } else {
              d['avg_label_val_moving_average'] = null;
            }
          } else {
            d['avg_label_val'] = null;
            d['avg_label_val_moving_average'] = null;
          }
          data.push(d);
        }
        if (data.length == 0) {
          this.renderPredictionError('No data available')
          return
        }
        // padding data
        // data = this.padData(data)
        // add "all" counts
        for (let i=0; i < data.length; i++) {
          let sum = 0;
          this.state.labels.forEach((label) => {
            sum += data[i][label];
          })
          data[i]['all'] = sum;
        }
        // get min/max of index value and
        let minIndexVal = Math.min(...data.filter((d) => d['avg_label_val'] != null).map(d => d['avg_label_val'])) * 0.7;
        let maxIndexVal = Math.max(...data.filter((d) => d['avg_label_val'] != null).map(d => d['avg_label_val'])) * 1.3;
        // move curve up a bit
        minIndexVal -= 2*(maxIndexVal - minIndexVal)
        this.setState({
          data: data,
          isLoadingPredictions: false,
          minIndexVal: minIndexVal,
          maxIndexVal: maxIndexVal,
        })
      },
      error: (predictions) => {
        this.renderPredictionError("Something went wrong when trying to load the data. Sorry ¯\\_(ツ)_/¯")
      }
    })
  }

  padData(data) {
    // Legacy function, only needed when plotting in d3, handled by min/max arguments in chart.js
    // pad data with zeroes in the beginning and end of the range (if data is missing)
    const startDaterange = this.daterange(this.parseDate(this.state.startDate), this.parseDate(data[0].date), this.state.interval);
    let padZeroes = {}
    this.state.labels.forEach((label) => {
      padZeroes[label] = 0;
    })
    for (let i=startDaterange.length-1; i >= 0; i--) {
      const d = {date: startDaterange[i], ...padZeroes}
      data.unshift(d)
    }
    const endDaterange = this.daterange(this.parseDate(data.slice(-1)[0].date), this.parseDate(this.state.endDate).subtract(1, this.state.interval), this.state.interval);
    for (let i=0; i < endDaterange.length; i++) {
      const d = {date: endDaterange[i], ...padZeroes}
      data.push(d)
    }
    return data
  }

  parseDate(date) {
    if (date == 'now') {
      return moment.utc();
    } else if (date.startsWith('now-')) {
      let sub = date.split('-')[1]
      const unit = sub[sub.length - 1];
      const multiplier = Number(sub.substring(0, sub.length - 1));
      if (unit == 'y') {
        return moment.utc().subtract(multiplier, 'year')
      } else if (unit == 'M') {
        return moment.utc().subtract(multiplier, 'month')
      } else if (unit == 'd') {
        return moment.utc().subtract(multiplier, 'day')
      }
    } else {
      const parsedDate = moment.utc(date);
      if (parsedDate.isValid()) {
        return parsedDate
      }
      console.error('Cannot parse date '+date+'. Fallback to now.')
      return moment.utc();
    }
  }

  renderPredictionError(msg) {
    this.setState({
      predictionsErrorNotification: msg,
      predictionsError: true,
      isLoadingPredictions: false
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

  init() {
    // Get endpoint info
    $.ajax({
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      type: "POST",
      url: this.props.endpointInfoPath,
      dataType: "json",
      contentType: "application/json",
      success: (endpointInfo) => {
        let stateUpdate = {
          endpointInfo: endpointInfo,
          isLoadingEndpointInfo: false
        }
        if (Object.keys(endpointInfo).length > 0) {
          let project = Object.keys(endpointInfo)[0]
          let questionTag = Object.keys(endpointInfo[project])[0]
          let endpoints = endpointInfo[project][questionTag]['endpoints']
          let labels = endpointInfo[project][questionTag]['labels']
          let runName = ''
          for (let i=0; i < endpoints.length; i++) {
            if (endpoints[i]['is_primary']) {
              runName = endpoints[i]['run_name'];
              break;
            }
          }
          stateUpdate['project'] = project
          stateUpdate['questionTag'] = questionTag
          stateUpdate['runName'] = runName
          stateUpdate['labels'] = labels
          stateUpdate['endpointsFound'] = true;
        }
        this.setState(stateUpdate, () => this.getPredictions())
      }
    })
  }

  onSelectField(field, value) {
    let currentState = this.state;
    currentState[field] = value;
    currentState['isLoadingPredictions'] = true;
    this.setState(currentState, () => this.getPredictions())
  }

  optionName(item) {
    let primaryTag = '';
    if (item['is_primary']) {
      primaryTag = ' (primary)'
    }
    return item['endpoint_name'] + ' - ' + item['run_name'] + primaryTag
  }

  getSelectEndpoint() {
    let prevThis = this;
    let selectEndpoint = <select name="endpoint-select" value={this.state.runName} className='select form-control' onChange={(e) => this.onSelectField('runName', e.target.value)}>
    {this.state.endpointInfo[this.state.project][this.state.questionTag]['endpoints'].map((item, i) => {
      return <option key={i} value={item['run_name']}>{prevThis.optionName(item)}</option>
    })}
    </select>
    return selectEndpoint
  }

  getSelectProject() {
    let prevThis = this;
    let selectProject = <select name="endpoint-select" value={this.state.project} className='select form-control' onChange={(e) => this.onSelectField('project', e.target.value)}>
      {Object.keys(this.state.endpointInfo).map((item, i) => {
        return <option key={i} value={item}>{item}</option>
      })}
      </select>
    return selectProject
  }

  getSelectQuestion() {
    let prevThis = this;
    let selectQuestion = <select name="endpoint-select" value={this.state.questionTag} className='select form-control' onChange={(e) => this.onSelectField('questionTag', e.target.value)}>
      {Object.keys(this.state.endpointInfo[this.state.project]).map((item, i) => {
        return <option key={i} value={item}>{item}</option>
      })}
      </select>
    return selectQuestion
  }

  getGraphData() {
    const commonCountOptions = {
      spanGaps: true,
      yAxisID: 'counts'
    }
    let datasets = this.state.labels.map((label, i) => {
      return {
        label: label,
        backgroundColor: this.getColor(label, i),
        borderColor: this.getColor(label, i),
        data: this.state.data.map((d) => d[label]),
        ...commonCountOptions
      }
    })
    datasets.push({
      label: 'all',
      data: this.state.data.map((d) => d['all']),
      ...commonCountOptions
    })
    datasets.push({
      label: 'index',
      yAxisID: 'index',
      borderColor: '#657786',
      backgroundColor: '#657786',
      pointRadius: 2,
      showLine: false,
      data: this.state.data.map((d) => d['avg_label_val'])
    })
    datasets.push({
      label: 'index (moving average)',
      yAxisID: 'index',
      borderColor: '#657786',
      backgroundColor: '#657786',
      spanGaps: true,
      borderWidth: 4,
      pointRadius: 0,
      data: this.state.data.map((d) => d['avg_label_val_moving_average'])
    })
    const data = {
      labels: this.state.data.map((d) => d['date']),
      datasets: datasets
    };
    return data
  }

  getColor(label, i) {
    const defaultColors = [
      '#1e9CeA', // blue
      '#db4457', // red
      '#fd7e14', // orange
      '#ffc107', // yellow
      '#5bb12a' // green
    ];

    if (label === 'positive') {
      return '#5bb12a'
    } else if (label === 'negative') {
      return '#db4457'
    } else if (label === 'neutral') {
      return '#1e9CeA'
    } else {
      i = i % defaultColors.length;
      return defaultColors[i];
    }
  }

  getOptions() {
    return {
      scales: {
        yAxes: [
          {
            stacked: true,
            id: "counts",
            scaleLabel: {
              display: true,
              labelString: "Counts"
            },
            ticks: {
              min: 0
            }
          },{
            id: "index",
            position: "right",
            scaleLabel: {
              display: true,
              labelString: "Index"
            },
            ticks: {
              suggestedMin: this.state.minIndexVal,
              suggestedMax: this.state.maxIndexVal,
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
          },
          ticks: {
            min: this.parseDate(this.state.startDate),
            max: this.parseDate(this.state.endDate),
          },
        }]
      },
      elements: {
        line: {
          tension: 0,
          fill: false,
        }
      }
    }
  }

  onChangeInputFields(field, e) {
    let currentState = this.state;
    currentState[field] = e.target.value;
    this.setState(currentState);
  }

  refresh() {
    this.setState({
      startDate: this.state.startDateValue,
      endDate: this.state.endDateValue,
      interval: this.state.intervalValue,
      isLoadingPredictions: true
    }, () => this.getPredictions())
  }

  render() {
    let input;
    if (this.state.isLoadingEndpointInfo) {
      input =
        <div className='loading-notification-container'>
          <div className="loading-notification">
            <div className="spinner-small"></div>
          </div>
        </div>
    } else {
      if (this.state.endpointsFound) {
        let selectEndpoint = this.getSelectEndpoint();
        let selectQuestion = this.getSelectQuestion();
        let selectProject = this.getSelectProject();
        input = <div>
          <div className='form-group mb-3'>
            <label>Projects</label>
            {selectProject}
          </div>
          <div className='form-group mb-3'>
            <label>Questions</label>
            {selectQuestion}
          </div>
          <div className='form-group mb-3'>
            <label>Endpoints</label>
            {selectEndpoint}
          </div>
          <div className="row mb-3">
            <div className="col-xs-12 col-lg-3">
              <div className='form-group field_with_hint mb-0'>
                <label>Start</label>
                <input className='form-control' type="text" value={this.state.startDateValue} onChange={(e) => this.onChangeInputFields('startDateValue', e)}/>
                <p className='help-block'>YYYY-MM-dd HH:mm:ss</p>
              </div>
            </div>
            <div className="col-xs-12 col-lg-3">
              <div className='form-group field_with_hint mb-0'>
                <label>End</label>
                <input className='form-control' type="text" value={this.state.endDateValue} onChange={(e) => this.onChangeInputFields('endDateValue', e)}/>
                <p className='help-block'>YYYY-MM-dd HH:mm:ss</p>
              </div>
            </div>
            <div className="col-xs-12 col-lg-3">
              <div className='form-group'>
                <label>Interval</label>
                <select className='form-control' type="select form-control" value={this.state.intervalValue} onChange={(e) => this.onChangeInputFields('intervalValue', e)} >
                {
                  this.intervalOptions.map((item, i) => {
                    return <option key={i} value={item}>{item}</option>
                  })
                }
                </select>
              </div>
            </div>
            <div className='col-xs-12 col-lg-3'>
              <button className='btn btn-secondary' style={{marginTop: '33px'}} onClick={() => this.refresh()}>Refresh&ensp;<i className='fa fa-refresh'></i></button>
            </div>
          </div>
        </div>
      } else {
        input = <div className="alert alert-primary">No active endpoints could be found.</div>
      }
    }

    let graph;
    if (this.state.isLoadingPredictions) {
      graph =
          <div className='loading-notification-container'>
            <div className='loading-notification'>
              <div className='spinner'></div>
            </div>
          </div>
    } else {
      if (this.state.predictionsError) {
        graph = <div className="alert alert-primary">{this.state.predictionsErrorNotification}</div>
      } else {
        graph = <Line data={this.getGraphData()} width={600} height={250} options={this.getOptions()} />
      }
    }

    return(
      <div>
        <div>
          {input}
        </div>
        <div>
          {graph}
        </div>
      </div>
    )
  }
}
