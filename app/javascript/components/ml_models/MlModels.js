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
      isLoadingData: true
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
        console.log(data);
        this.setState({
          data: data,
          isLoadingData: false
        });
      }
    });
  }

  update(updateAction) {
    $.ajax({
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      type: "POST",
      url: this.props.updateMlModelsEndpoint,
      data: JSON.stringify(updateAction),
      dataType: "json",
      contentType: "application/json",
      error: (data) => {
        toastr.error(data['message'])
      },
      success: (data) => {
        toastr.success(data['message'])
        this.getData(true)
      }
    });
  }

  onUpdateAction(action, modelName, projectName) {
    const updateData = {
      'ml': {
        'action': action,
        'model_name': modelName,
        'project_name': projectName,
      }
    }
    console.log(updateData);
    this.update(updateData)
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
                  onUpdateAction={(...e) => prevThis.onUpdateAction(...e)}
                />
              </td>
              <td>
                <PipelineAction
                  status={item['EndpointStatus']}
                  activeEndpoint={item['ActiveEndpoint']}
                  modelName={item['ModelName']}
                  projectName={item['Tags']['project_name']}
                  onUpdateAction={(...e) => prevThis.onUpdateAction(...e)}
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
