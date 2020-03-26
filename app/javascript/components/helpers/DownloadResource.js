// React
import React from 'react'
import moment from 'moment';

export class DownloadResource extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      isLoading: true,
      isLoadingError: false,
      size: null,
      lastUpdated: null
    }
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
        console.log(data);
        this.setState({
          lastUpdated: moment(data['last_modified']).calendar(),
          size: this.parseSize(data['size']),
          isLoading: false
        })
      },
      error: (data) => {
        this.setState({
          isLoading: false,
          isLoadingError: true
        })
      }
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


  getUrl() {
    return 'https://crowdbreaks-public.s3.eu-central-1.amazonaws.com/data_dump/' +
      this.props.project +
      '/data_dump_ids_' +
      this.props.project +
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
          <a href={this.getUrl()} _target='_blank' className='btn btn-secondary mb-2'>
            <i className='fa fa-download'></i>
            &ensp;Download
          </a>
          <div className='text-light-sm'>
            Size: {this.state.size}
          </div>
          <div className='text-light-sm'>
            Last updated: {this.state.lastUpdated}
          </div>
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
