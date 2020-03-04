// React
import React from 'react';

// Sub-components
import { EndpointStatus } from './EndpointStatus';
import { EndpointAction } from './EndpointAction';
import { PipelineAction } from './PipelineAction';

let moment = require('moment');

export class MlModels extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      data: [],
      isLoadingData: true,
      isLoadingEndpoint: []
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
        const isLoadingEndpoint = new Array(data.length).fill(false);
        this.setState({
          isLoadingData: false,
          data: data,
          isLoadingEndpoint: isLoadingEndpoint
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
        const isLoadingEndpoint = new Array(data.length).fill(false);
        this.setState({
          isLoadingData: false,
          isLoadingEndpoint: isLoadingEndpoint
        });
      },
      success: (data) => {
        toastr.success(data['message'])
        let action = updateAction['ml']['action']
        if (!['activate_endpoint', 'deactivate_endpoint'].includes(action)) {
          this.getData(false)
        } else {
          this.toggleActivateEndpoint(idx);
        }
      }
    });
  }

  toggleActivateEndpoint(idx) {
    let data = this.state.data;
    data[idx]['ActiveEndpoint'] = !data[idx]['ActiveEndpoint']
    this.setState({
      data: data
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
      let isLoadingEndpoint = this.state.isLoadingEndpoint;
      isLoadingEndpoint[idx] = true;
      this.setState({
        isLoadingEndpoint: isLoadingEndpoint
      })
    }
    this.update(updateData, idx)
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
            <th>Endpiont action</th>
            <th>Use in pipeline?</th>
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
                  isLoadingEndpoint={this.state.isLoadingEndpoint[i]}
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
            </tr>
          })}
        </tbody>
        body = <table className="table">
          {thead}
          {tbody}
        </table>
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
