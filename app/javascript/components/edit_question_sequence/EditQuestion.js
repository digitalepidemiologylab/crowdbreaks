import React from 'react'
import PropTypes from 'prop-types';

export class EditQuestion extends React.Component {
  constructor(props) {
    super(props);
    var editMode = false;
    if (props.question == '') {
      editMode = true;
    }
    this.state = {
      internalQuestion: props.question,
      editMode: editMode
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
    const buttonStyle = {margin: '0px 10px 10px 0px'}; 
    return (
      <tr>
        <td>{this.props.questionId}</td>
        <td>{question}</td>
        <td>
          {!this.state.editMode && <div>
            <button 
              onClick={() => this.startEditMode()}
              style={buttonStyle}
              className="btn btn-secondary">Edit
            </button>
            <button 
              onClick={(questionId, e) => this.props.onDeleteQuestion(questionId, e)}
              style={buttonStyle}
              className="btn btn-negative">Delete
            </button>
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
    );
  }
};
