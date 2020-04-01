// React
import React from 'react'
import moment from 'moment';

export class DownloadResource extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      isLoading: true,
      isLoadingError: false,
      data: null
    }
    this.modes = [
      {name: 'all', prefix: '', title: 'All'},
      {name: 'place', prefix: '_has_place', title: 'Place'},
      {name: 'coordinates', prefix: '_has_coordinates', title: 'Exact location'}
    ];
  }


  componentDidMount() {
    const data = {
      download_resource: {
        project: this.props.project
      }
    };
    $.ajax({
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      type: 'POST',
      url: this.props.downloadResourceInfoPath,
      data: JSON.stringify(data),
      dataType: "json",
      contentType: "application/json",
      success: (data) => {
        const noneExist = this.modes.every((d) => data[d.name].exists === false)
        if (noneExist) {
          this.switchToErrorState()
        } else {
          this.setState({
            isLoading: false,
            data: data
          })
        }
      },
      error: (data) => {
        this.switchToErrorState()
      }
    })
  }

  switchToErrorState() {
    this.setState({
      isLoading: false,
      isLoadingError: true
    })
  }

  parseSize(size) {
    if (size < 1e2) {
      return size + ' bytes'
    } else if (size < 1e5) {
      size = Math.round(10*(size/1e3))/10;
      return size + ' kB'
    } else if (size < 1e8) {
      size = Math.round(10*(size/1e6))/10;
      return size + ' MB'
    }
    size = Math.round(10*(size/1e9))/10;
    return size + ' GB'
  }


  getUrl(prefix) {
    return 'https://crowdbreaks-public.s3.eu-central-1.amazonaws.com/data_dump/' +
      this.props.project +
      '/data_dump_ids_' +
      this.props.project +
      prefix +
      '.txt.gz'
  }

  render() {
    let body;
    if (!this.state.isLoadingError) {
      if (this.state.isLoading) {
        body =
          <div className='loading-notification-container-sm'>
            <div className="loading-notification">
              <div className="spinner-small"></div>
            </div>
          </div>
      } else {
        body = <div>
          {
            this.modes.map((mode, i) => {
              if (this.state.data[mode.name].exists) {
                return <div key={i} className='mb-3'>
                  <a href={this.getUrl(mode['prefix'])} _target='_blank' className='btn btn-secondary mb-2'>
                    <i className='fa fa-download'></i>
                    &ensp;{mode.title}
                  </a>
                  <div className='text-light-sm'>
                    Size: {this.parseSize(this.state.data[mode.name].size)}
                  </div>
                  <div className='text-light-sm'>
                    Last updated: {moment(this.state.data[mode.name].last_modified).calendar()}
                  </div>
                </div>
              }
          })
        }
        </div>
      }
    } else {
      body = <div className='alert alert-primary'>
        The data are temporarily not availble. Please get in touch.
      </div>
    }

    return(
      <div className='mb-5'>
        {body}
      </div>
    )
  }
}
