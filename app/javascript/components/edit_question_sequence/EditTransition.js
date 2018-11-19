import React from 'react'
import PropTypes from 'prop-types';

// Other

export class EditTransition extends React.Component {
  constructor(props) {
    super(props);
    let isStartingNode = false;
    let editMode = false;
    if (props.sourceId == 'start') {
      isStartingNode = true;
    } else if (props.sourceId == '') {
      editMode = true;
    }
    let answerId = props.transition.answer;
    if (answerId == null) {
      answerId = '';
    }
    this.state = {
      editMode: editMode,
      internalTargetId: props.transition.to_question,
      internalAnswerId: answerId,
      internalSourceId: props.sourceId,
      isStartingNode: isStartingNode,
    };
  }

  startEditMode() {
    this.setState({
      editMode: true
    })
  }

  stopEditMode(mode) {
    if (mode == 'ok') {
      let new_transition = {
        'id': this.props.transitionId,
        'from_question': this.state.internalSourceId,
        'transition': {
          'to_question': this.state.internalTargetId,
          'answer': this.state.internalAnswerId
        },
      };
      if (this.props.validateTransition(new_transition)){
        this.props.onUpdateTransition(new_transition)
      } else {
        this.setState({
          internalAnswerId: this.props.transition.answer,
          internalTargetId: this.props.transition.to_question,
          internalSourceId: this.props.sourceId
        })
      }
    }
    this.setState({
      editMode: false
    })
  }

  handleInputChangeSource(e) {
    this.setState({internalSourceId: e.target.value})
  }

  handleInputChangeTarget(e) {
    this.setState({internalTargetId: e.target.value})
  }

  handleInputChangeAnswer(e) {
    this.setState({internalAnswerId: e.target.value})
  }

  render() {
    const buttonStyle = {margin: '0px 10px 0px 0px'}; 
    const inputStyle = {width: '60px'}; 
    let sourceId = this.props.sourceId;
    let targetId = this.props.transition.to_question;
    let answerId = this.props.transition.answer;

    if (this.state.editMode) {
      if (!this.state.isStartingNode) {
        sourceId = <input 
          value={this.state.internalSourceId} 
          type='text' 
          className="form-control"
          onChange={(e) => this.handleInputChangeSource(e)}
          style={inputStyle}>
        </input>
        answerId = <input 
          value={this.state.internalAnswerId} 
          type='text' 
          className="form-control"
          onChange={(e) => this.handleInputChangeAnswer(e)}
          style={inputStyle}>
        </input>
      }
      targetId = <input 
        value={this.state.internalTargetId} 
        type='text' 
        className="form-control"
        onChange={(e) => this.handleInputChangeTarget(e)}
        style={inputStyle}>
      </input>
    }
    return (
      <tr>
        <td>{sourceId}</td>
        <td>{targetId}</td>
        <td>{answerId}</td>
        <td>
          {!this.state.editMode && <div>
            <button 
              onClick={() => this.startEditMode()}
              style={buttonStyle}
              className="btn btn-secondary">Edit
            </button>
            {!this.state.isStartingNode && <button 
              onClick={(questionId, e) => this.props.onDeleteTransition(this.props.transitionId, e)}
              style={buttonStyle}
              className="btn btn-negative">Delete
            </button> }
          </div>
          }
          { this.state.editMode && <div>
            <button
              onClick={() => this.stopEditMode('ok')}
              className="btn btn-primary"
              style={buttonStyle}
            >OK</button>
            <button
              className="btn btn-secondary"
              style={buttonStyle}
              onClick={() => this.stopEditMode('cancel')}
            >Cancel</button>
            </div>
          }
        </td>
      </tr>
    )
  }
}
