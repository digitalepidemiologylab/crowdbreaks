// React
import React from 'react'
import { Line, defaults } from 'react-chartjs-2';
import moment from 'moment';

export class PredictViz extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      data: {},
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
      interval: 'day',
      timeAxis: []
    };
    this.options = {
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
              suggestedMin: -1,
              suggestedMax: 1,
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

  }

  componentDidMount() {
    this.init();
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
      success: (predictions) => {
        const arrayLengths = this.state.labels.map((label) => predictions[label].length)
        const maxLengthKey = this.state.labels[arrayLengths.indexOf(Math.max(...arrayLengths))]
        let data = [];
        let counters = {};
        this.state.labels.forEach((label) => {
          counters[label] = 0;
        });
        for (let i=0; i < predictions[maxLengthKey].length; i++) {
          let d = {'date': new Date(moment.utc(predictions[maxLengthKey][i].key_as_string))}
          this.state.labels.forEach((label) => {
            if (predictions[label][counters[label]] && predictions[label][counters[label]].key_as_string === predictions[maxLengthKey][i].key_as_string) {
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
          data.push(d);
        }
        if (data.length == 0) {
          this.setState({
            predictionsErrorNotification: "Something went wrong when trying to load the data. Sorry ¯\\_(ツ)_/¯",
            predictionsError: true,
            isLoadingPredictions: false
          })
          return
        }
        // pad data with zeroes in the beginning and end of the range (if data is missing)
        const startDaterange = this.daterange(moment.utc(this.state.start_date), moment(data[0].date), this.state.interval);
        let padZeroes = {}
        this.state.labels.forEach((label) => {
          padZeroes[label] = 0;
        })
        for (let i=startDaterange.length-1; i >= 0; i--) {
          const d = {date: startDaterange[i], ...padZeroes}
          data.unshift(d)
        }
        const endDaterange = this.daterange(moment(data.slice(-1)[0].date), moment.utc(this.state.end_date).subtract(1, this.state.interval), this.state.interval);
        for (let i=0; i < endDaterange.length; i++) {
          const d = {date: endDaterange[i], ...padZeroes}
          data.push(d)
        }
        // add "all" counts
        for (let i=0; i < data.length; i++) {
          let sum = 0;
          this.state.labels.forEach((label) => {
            sum += data[i][label];
          })
          data[i]['all'] = sum;
        }
        console.log(data);
        this.setState({
          data: data,
          isLoadingPredictions: false
        })
      }
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
        console.log(endpointInfo);
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

  onSelectEndpoint(runName) {
    this.setState({
      runName: runName
    }, () => this.getPredictions())
  }

  onSelectProject(project) {
    this.setState({
      project: project
    })
  }

  onSelectQuestion(question) {
    this.setState({
      question_tag: question
    })
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
    let selectEndpoint = <select name="endpoint-select" value={this.state.runName} className='select form-control mb-3' onChange={(e) => this.onSelectEndpoint(e.target.value)}>
    {this.state.endpointInfo[this.state.project][this.state.questionTag]['endpoints'].map((item, i) => {
      return <option key={i} value={item['run_name']}>{prevThis.optionName(item)}</option>
    })}
    </select>
    return selectEndpoint
  }

  getSelectProject() {
    let prevThis = this;
    let selectProject = <select name="endpoint-select" value={this.state.project} className='select form-control mb-3' onChange={(e) => this.onSelectProject(e.target.value)}>
      {Object.keys(this.state.endpointInfo).map((item, i) => {
        return <option key={i} value={item}>{item}</option>
      })}
      </select>
    return selectProject
  }

  getSelectQuestion() {
    let prevThis = this;
    let selectQuestion = <select name="endpoint-select" value={this.state.questionTag} className='select form-control mb-3' onChange={(e) => this.onSelectQuestion(e.target.value)}>
      {Object.keys(this.state.endpointInfo[this.state.project]).map((item, i) => {
        return <option key={i} value={item}>{item}</option>
      })}
      </select>
    return selectQuestion
  }

  getGraphData() {
    let datasets = this.state.labels.map((label, i) => {
      return {
        label: label,
        backgroundColor: this.getColor(label, i),
        borderColor: this.getColor(label, i),
        data: this.state.data.map((d) => d[label])
      }
    })
    datasets.push({
      label: 'all',
      data: this.state.data.map((d) => d['all'])
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
        input = <div className='form-group'>
          <label>Projects</label>
          {selectProject}
          <label>Questions</label>
          {selectQuestion}
          <label>Endpoints</label>
          {selectEndpoint}
        </div>
      } else {
        input = <div className="alert alert-primary">No active endpoints could be found.</div>
      }
    }

    let graph;
    if (this.state.isLoadingPredictions) {
      graph =
          <div className='loading-notification-container'>
            <div className="loading-notification">
              <div className="spinner spinner-with-text"></div>
              <div className='spinner-text'>Loading predictions...</div>
            </div>
          </div>
    } else {
      if (this.state.predictionsError) {
        graph = <div className="alert alert-primary">{this.state.predictionsErrorNotification}</div>
      } else {
        console.log(this.state.data);
        graph = <Line data={this.getGraphData()} width={600} height={250} options={this.options} />
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
