// React
import React from 'react';

// Sub-components
import { EndpointStatus } from './EndpointStatus';
import { EndpointAction } from './EndpointAction';
import { PipelineAction } from './PipelineAction';
import { Actions } from './Actions';

let moment = require('moment');

export class MlModels extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      data: [],
      isLoadingData: true,
      isLoadingEndpointAction: [],
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
          isLoadingActions: [...loadingActions]
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
          isLoadingActions: [...loadingActions]
        });
      },
      success: (data) => {
        let action = updateAction['ml']['action']
        if (['activate_endpoint', 'deactivate_endpoint'].includes(action)) {
          this.toggleActivateEndpoint(idx, data['message']);
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

  onUpdateAction(action, modelName, projectName, idx) {
    const updateData = {
      'ml': {
        'action': action,
        'model_name': modelName,
        'project_name': projectName,
      }
    }
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
            <th>Project</th>
            <th>Question tag</th>
            <th>Endpoint status</th>
            <th>Modify endpoint</th>
            <th>Use in pipeline?</th>
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
              <td>{item['Tags']['project_name']}</td>
              <td>{item['Tags']['question_tag']}</td>
              <td><EndpointStatus status={item['EndpointStatus']} /></td>
              <td>
                <EndpointAction
                  status={item['EndpointStatus']}
                  modelName={item['ModelName']}
                  projectName={item['Tags']['project_name']}
                  onUpdateAction={(...e) => prevThis.onUpdateAction(...e, i)}
                  isLoadingEndpointAction={this.state.isLoadingEndpointAction[i]}
                />
              </td>
              <td>
                <PipelineAction
                  status={item['EndpointStatus']}
                  activeEndpoint={item['ActiveEndpoint']}
                  modelName={item['ModelName']}
                  projectName={item['Tags']['project_name']}
                  onUpdateAction={(...e) => prevThis.onUpdateAction(...e, i)}
                />
              </td>
              <td>
                <Actions
                  onUpdateAction={(...e) => prevThis.onUpdateAction(...e, i)}
                  modelName={item['ModelName']}
                  projectName={item['Tags']['project_name']}
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
