import React from 'react'
import PropTypes from 'prop-types';

export class EditQuestion extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      internalQuestion: props.question,
      editMode: false
    };
  }

  startEditMode() {
    this.setState({
      editMode: true
    })
  }

  stopEditMode(mode) {
    var new_question = this.props.question;
    if (mode == 'ok') {
      new_question = this.state.internalQuestion;
      this.props.onUpdateQuestion({'question': new_question, 'id': this.props.questionId})
    }
    this.setState({
      editMode: false
    })
  }

  handleInputChange(e) {
    this.setState({internalQuestion: e.target.value})
  }

  render() {
    let question = this.props.question
    if (this.state.editMode) {
      question = <textarea 
        value={this.state.internalQuestion} 
        type='text' 
        className="form-control"
        onChange={(e) => this.handleInputChange(e)}
        rows='2'>
      </textarea>
    }
    return (
      <tr>
        <td>{this.props.questionId}</td>
        <td>{question}</td>
        <td>
          {!this.state.editMode && <button 
            key={this.props.questionId} 
            onClick={() => this.startEditMode()}
            className="btn btn-secondary">Edit
          </button>
          }
          { this.state.editMode && <span>
            <button
              onClick={() => this.stopEditMode('ok')}
              className="btn btn-primary"
              style={{marginBottom: '10px'}}
            >OK</button>
            <button
              className="btn btn-secondary"
              onClick={() => this.stopEditMode('cancel')}
            >Cancel</button>
            </span>
          }
        </td>
      </tr>
    );
  }
};
