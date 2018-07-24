import React from 'react'
import PropTypes from 'prop-types';

export class EditQuestion extends React.Component {
  constructor(props) {
    super(props);
    var editMode = false;
    var editModeInstructions = false;
    if (props.question == '') {
      editMode = true;
      if (props.instructions != '') {
        editModeInstructions = true;
      }
    }
    this.state = {
      internalQuestion: props.question,
      editMode: editMode,
      editInstructions: editModeInstructions,
      internalInstructions: props.instructions
    };
  }

  startEditMode() {
    console.log(this.state.internalInstructions)
    this.setState({
      editMode: true,
      editInstructions: this.state.internalInstructions == "" ? false : true
    })
  }

  stopEditMode(mode) {
    if (mode == 'ok') {
      this.props.onUpdateQuestion({
        'id': this.props.questionId,
        'question': this.state.internalQuestion,
        'instructions': this.state.internalInstructions
      })
    }
    this.setState({
      editMode: false,
      editInstructions: false
    })
  }

  handleInputChange(e) {
    this.setState({internalQuestion: e.target.value})
  }

  handleInputChangeInstructions(e) {
    this.setState({internalInstructions: e.target.value})
  }

  startEditInstructions() {
    this.setState({
      editInstructions: true
    })
  }

  render() {
    let question = this.props.question
    if (this.state.editMode) {
      question = <div>
        <textarea 
          value={this.state.internalQuestion} 
          type='text'
          style={{marginBottom: '20px'}}
          className="form-control"
          onChange={(e) => this.handleInputChange(e)}
          rows='2'>
        </textarea>
        {!this.state.editInstructions && <button 
            onClick={() => this.startEditInstructions()}
            className="btn btn-secondary">
            <i className='fa fa-plus' style={{color: '#212529'}}></i>&emsp;Add instructions
          </button>}
          {this.state.editInstructions && <div>
            <h4>Instructions (use Markdown)</h4>
            <textarea 
              value={this.state.internalInstructions} 
              type='text' 
              style={{fontFamily: 'monospace'}}
              className="form-control"
              onChange={(e) => this.handleInputChangeInstructions(e)}
              rows='4'>
            </textarea>
          </div>}
      </div>
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
