// React
import React from 'react'
// Sub-components
import { AssignmentReview } from './AssignmentReview';
// Other
let moment = require('moment');

export class Assignment extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      'isLoading': false,
      'assignmentId': null,
      'status': null,
      'submitTime': null,
      'statusChangedTime': null,
      'reviewable': false,
    }
  }

  componentWillMount() {
    this.refresh();
  }

  refresh() {
    this.setState({
      'isLoading': true,
    })
    $.ajax({
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      type: "GET",
      url: this.props.refresh_path,
      data: {hit_id: this.props.hit_id},
      dataType: "json",
      contentType: "application/json",
      success: (assignment) => {
        let newState = {
          'isLoading': false,
          'assignmentId': assignment['assignment_id'],
          'status': this.assignmentStatus(assignment),
          'submitTime': assignment['submit_time'],
        };
        switch (newState['status']) {
          case 'Submitted':
            newState['reviewable'] = true;
            break;
          case 'Approved':
            newState['statusChangedTime'] = assignment['approval_time'];
            break;
          case 'Rejected':
            newState['statusChangedTime'] = assignment['rejection_time'];
            break;
          case 'Auto-approved':
            newState['statusChangedTime'] = assignment['auto_approval_time'];
            break;
        }
        this.setState(newState);
      }
    });
  }

  assignmentStatus(assignment) {
    let status = assignment['assignment_status'];
    if (status == 'Approved') {
      if (this.wasAutoApproved(assignment['auto_approval_time'], assignment['approval_time'])) {
        return 'Auto-approved'
      };
    }
    return status;
  }

  wasAutoApproved(autoApprovalTime, approvalTime) {
    let timeDiff = Math.abs(moment(autoApprovalTime) - moment(approvalTime));
    if (timeDiff < 10000) {
      // auto approval and approval happened within 10 seconds
      return true
    } else {
      return false
    }
  }

  tableRow(label, value) {
    return <tr>
      <td style={{'textAlign': 'left'}}><h4>{label}</h4></td>
      <td style={{'textAlign': 'right'}}>{value}</td>
    </tr>
  }

  renderStatusChangeTime() {
    if (this.state.status == 'Submitted') {
      return null;
    }
    switch (this.state.status) {
      case 'Auto-approved':
      case 'Approved':
        return this.tableRow('Approval time', moment(this.state.statusChangedTime).fromNow())
      case 'Rejected':
        return this.tableRow('Rejection time', moment(this.state.statusChangedTime).fromNow())
    }
  }

  render() {
    const centerStyle = {'margin': 'auto'}
    return <div>
      <h4 className='card-title'>HIT Assignment</h4>
      {this.state.isLoading && <div className='spinner' style={centerStyle}></div>} 
      {!this.state.isLoading && <div>
        <div style={{'position': 'absolute', 'top': '10px', 'right': '10px'}}>
          <button onClick={() => this.refresh()} className='btn p-0'><i className="fa fa-refresh"></i></button>
        </div>
        <table className='table vertical-align borderless-table'>
          <tbody>
            {this.tableRow('HIT Id', this.props.hit_id)}
            {this.tableRow('Assignment Id', this.state.assignmentId)}
            {this.tableRow('Status', this.state.status)}
            {this.renderStatusChangeTime()}
            {this.tableRow('Submit time', moment(this.state.submitTime).fromNow())}
          </tbody>
        </table>
        {this.state.reviewable && <AssignmentReview 
          reviewPath={this.props.review_path}
          defaultApproveMessage={this.props.default_approve_message}
          defaultRejectMessage={this.props.default_reject_message}
          assignmentId={this.state.assignmentId}
          refresh={() => this.refresh()}
        />}
      </div>}
    </div>
  }
}
