// React
import React from 'react'
// Other
let humps = require('humps');
import { ClipLoader } from 'react-spinners';

export class AssignmentReview extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      'reviewing': false,
      'submitted': false,
      'submitStatusMsg': '',
      'approveMessage': props.defaultApproveMessage,
      'rejectMessage': props.defaultRejectMessage,
      'error': false
    }
  }

  onClickReviewBtn() {
    this.setState({
      'reviewing': true,
    })
  }

  onHandleChangeApprove(e) {
    this.setState({
      approveMessage: e.target.value
    })

  }

  onHandleChangeReject(e) {
    this.setState({
      rejectMessage: e.target.value
    })
  }

  onAccept() {
    if (this.state.approveMessage == '') {
      alert("Approve message can't be blank!")
      return
    }
    this.submitReview(true, this.state.approveMessage)
  }

  onReject() {
    if (this.state.rejectMessage == '') {
      alert("Reject message can't be blank!")
      return
    }
    this.submitReview(false, this.state.rejectMessage)
  }

  submitReview(accept, msg) {
    this.setState({
      submitted: true,
    })
    this.forceUpdate()  // make sure loading spinner is shown
    let data = humps.decamelizeKeys({
      review: {
        assignmentId: this.props.assignmentId,
        accept: accept,
        message: msg,
      }
    })
    $.ajax({
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      type: "POST",
      url: this.props.reviewPath,
      data: JSON.stringify(data),
      dataType: "json",
      contentType: "application/json",
      success: () => {
        this.setState({
          submitted: true,
          submitStatusMsg: 'Successfully submitted review.',
        })
      },
      error: () => {
        this.setState({
          submitStatusMsg: 'Something went wrong when submitting the review.',
          error: true
        })
      }
    });
  }

  renderSubmitMsg() {
    if (this.state.submitStatusMsg == '')  {
      const centerStyle = {'margin': 'auto'}
      return <div className='spinner' style={centerStyle}></div> 
    } else {
      let textStyle = {};
      if (this.state.error) {
        textStyle = {color: 'red'};
      }
      return <div>
        <p style={textStyle}>{this.state.submitStatusMsg}</p>
        <button onClick={this.props.refresh} className='btn btn-primary'>Refresh</button>
      </div>
    }
  }


  renderReviewInterface() {
    return <div>
      <div className='form-group'>
        <label>Approve</label>
        <textarea className='form-control' type='text' onChange={(e) => this.onHandleChangeApprove(e)} value={this.state.approveMessage} />
        <button className='btn btn-primary btn-block mt-2' onClick={() => this.onAccept()}>Submit</button>
      </div>
      <div className='form-group'>
        <label>Reject</label>
        <textarea className='form-control' type='text' onChange={(e) => this.onHandleChangeReject(e)} value={this.state.rejectMessage} />
        <button className='btn btn-danger btn-block mt-2' onClick={() => this.onReject()}>Submit</button>
      </div>
    </div>
  }

  render() {
    return <div className='mt-2'>
      {!this.state.submitted && <div>
          {!this.state.reviewing && <button onClick={() => this.onClickReviewBtn()} className='btn btn-primary' >
            Review
          </button>}
          {this.state.reviewing && this.renderReviewInterface()}
        </div>}
      {this.state.submitted && <div>
        {this.renderSubmitMsg()}
      </div>}
    </div>
  }
}
