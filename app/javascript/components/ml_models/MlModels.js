// React
import React from 'react';

// Sub-components
import { EndpointStatus } from './EndpointStatus';
import { EndpointAction } from './EndpointAction';
import { PipelineAction } from './PipelineAction';
import { PrimaryEndpoint } from './PrimaryEndpoint';
import { Actions } from './Actions';

let moment = require('moment');

export class MlModels extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      data: [],
      isLoadingData: true,
      isLoadingEndpointAction: [],
      isLoadingPrimaryEndpoint: [],
      isLoadingActions: []
    };
  }

  componentDidMount() {
    this.getData(true)
  }

  getData(useCache) {
    const postData = {
      'ml': {
        'use_cache': useCache
      }
    }
    $.ajax({
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      type: "POST",
      crossDomain: true,
      url: this.props.listMlModelsEndpoint,
      data: JSON.stringify(postData),
      dataType: "json",
      contentType: "application/json",
      success: (data) => {
        const loadingActions = new Array(data.length).fill(false);
        this.setState({
          isLoadingData: false,
          data: data,
          isLoadingEndpointAction: loadingActions,
          isLoadingActions: [...loadingActions],
          isLoadingPrimaryEndpoint: [...loadingActions],
        });
      }
    });
  }

  update(updateAction, idx) {
    $.ajax({
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      type: "POST",
      url: this.props.updateMlModelsEndpoint,
      data: JSON.stringify(updateAction),
      dataType: "json",
      contentType: "application/json",
      error: (data) => {
        toastr.error(data['message'])
        const loadingActions = new Array(data.length).fill(false);
        this.setState({
          isLoadingData: false,
          isLoadingEndpointAction: loadingActions,
          isLoadingActions: [...loadingActions],
          isLoadingPrimaryEndpoint: [...loadingActions],
        });
      },
      success: (data) => {
        let action = updateAction['ml']['action']
        if (['activate_endpoint', 'deactivate_endpoint'].includes(action)) {
          // toggle knob
          this.toggleActivateEndpoint(idx, data['message']);
          // make sure correct primary index is shown (done here by modifying the state instead of reloading the data)
          let currentData = this.state.data;
          if (action == 'deactivate_endpoint' && currentData[idx]['IsPrimaryEndpoint']) {
            currentData[idx]['IsPrimaryEndpoint'] = false;
          } else if (action == 'activate_endpoint') {
            for (let i=0; i<currentData.length; i++) {
              if (i != idx) {
                if (currentData[idx]['Tags']['question_tag'] == currentData[i]['Tags']['question_tag'] && currentData[i]['IsPrimaryEndpoint']) {
                  return
                }
              }
              currentData[idx]['IsPrimaryEndpoint'] = true;
            }
          } else {
            return
          }
          this.setState({
            data: currentData
          })
        } else {
          this.getData(false)
        }
      }
    });
  }

  toggleActivateEndpoint(idx, message) {
    let data = this.state.data;
    data[idx]['ActiveEndpoint'] = !data[idx]['ActiveEndpoint']
    this.setState({
      data: data
    }, () => {
      toastr.success(message)
    })
  }

  onUpdateAction(action, idx) {
    const updateData = {
      'ml': {
        'action': action,
        'model_name': this.state.data[idx]['ModelName'],
        'project_name': this.state.data[idx]['Tags']['project_name'],
        'question_tag': this.state.data[idx]['Tags']['question_tag'],
        'run_name': this.state.data[idx]['Tags']['run_name'],
      }
    }
    console.log(updateData);
    if (['create_endpoint', 'delete_endpoint'].includes(action)) {
      let isLoadingEndpointAction = this.state.isLoadingEndpointAction;
      isLoadingEndpointAction[idx] = true;
      this.setState({
        isLoadingEndpointAction: isLoadingEndpointAction
      })
    } else if (action == 'delete_model') {
      let isLoadingActions = this.state.isLoadingActions;
      isLoadingActions[idx] = true;
      this.setState({
        isLoadingActions: isLoadingActions
      })
    } else if (action == 'make_primary') {
      let isLoadingPrimaryEndpoint = this.state.isLoadingPrimaryEndpoint;
      isLoadingPrimaryEndpoint[idx] = true;
      this.setState({
        isLoadingPrimaryEndpoint: isLoadingPrimaryEndpoint
      })
    }
    this.update(updateData, idx)
  }

  onRefresh() {
    this.setState({
      isLoadingData: true
    }, () => {
      this.getData(false);
    })
  }

  render() {
    let prevThis = this
    let body;
    if (this.state.isLoadingData) {
      body =
          <div className='loading-notification-container'>
            <div className="loading-notification">
              <div className="spinner spinner-with-text"></div>
              <div className='spinner-text'>Loading...</div>
            </div>
          </div>
    } else {
      if (this.state.data.length > 0) {
        const thead = <thead>
          <tr className='no-wrap'>
            <th>Name</th>
            <th>Created at</th>
            <th>Run name</th>
            <th>Project</th>
            <th>Question</th>
            <th>Endpoint status</th>
            <th>Modify</th>
            <th>Active</th>
            <th>Primary</th>
            <th>Actions</th>
          </tr>
        </thead>
        const tbody = <tbody>
          {this.state.data.map((item, i) => {
            return <tr key={i}>
              <td>{item['ModelName']}</td>
              <td>
                <div className='convert-by-moment'>
                  {moment(item['CreationTime']).fromNow()}
                </div>
              </td>
              <td>{item['Tags']['run_name']}</td>
              <td>{item['Tags']['project_name']}</td>
              <td>{item['Tags']['question_tag']}</td>
              <td><EndpointStatus status={item['EndpointStatus']} /></td>
              <td>
                <EndpointAction
                  status={item['EndpointStatus']}
                  onUpdateAction={(...e) => prevThis.onUpdateAction(...e, i)}
                  isLoadingEndpointAction={this.state.isLoadingEndpointAction[i]}
                  activeEndpoint={item['ActiveEndpoint']}
                />
              </td>
              <td>
                <PipelineAction
                  status={item['EndpointStatus']}
                  activeEndpoint={item['ActiveEndpoint']}
                  onUpdateAction={(...e) => prevThis.onUpdateAction(...e, i)}
                />
              </td>
              <td>
                <PrimaryEndpoint
                  isPrimaryEndpoint={item['IsPrimaryEndpoint']}
                  activeEndpoint={item['ActiveEndpoint']}
                  isLoadingPrimaryEndpoint={this.state.isLoadingPrimaryEndpoint[i]}
                  onUpdateAction={(...e) => prevThis.onUpdateAction(...e, i)}
                />
              </td>
              <td>
                <Actions
                  onUpdateAction={(...e) => prevThis.onUpdateAction(...e, i)}
                  isLoadingActions={this.state.isLoadingActions[i]}
                  status={item['EndpointStatus']}
                />
              </td>
            </tr>
          })}
        </tbody>
        let refreshBtn = <button className='btn btn-secondary mb-4' onClick={() => this.onRefresh()}><i className='fa fa-refresh'></i>&ensp;Refresh</button>
        body = <div>
          {refreshBtn}
          <table className="table">
            {thead}
            {tbody}
          </table>
        </div>
      } else {
        body = <div className="alert alert-primary">No models could be found</div>
      }
    }


    return(
      <div>
        {body}
      </div>
    );
  }
}
