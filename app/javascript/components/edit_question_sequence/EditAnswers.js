import React from 'react'
import PropTypes from 'prop-types';


import { SingleAnswer } from './SingleAnswer';
import { EditSingleAnswer } from './EditSingleAnswer';

export class EditAnswers extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      editMode: false
    };
  }

  startEditMode() {
    this.setState({
      editMode: true
    })
  }

  stopEditMode() {
    this.setState({
      editMode: false
    })
  }

  onUpdateInternalAnswer(e) {
    var dummyAnswers = this.props.answers;
    dummyAnswers[e.answerPos].answer = e.answer;
    dummyAnswers[e.answerPos].color = e.color;
    dummyAnswers[e.answerPos].label = e.label;
    this.props.onUpdateAnswers({'answers': dummyAnswers, 'questionId': this.props.questionId})
    this.setState({
      editMode: false
    })
  }

  render() {
    let answers;
    if (!this.state.editMode) {
      answers = <div className='buttons'>
        {
          this.props.answers.map( (answer, id) => {
            return <SingleAnswer
              key={id}
              answer={answer.answer}
              color={answer.color}
              colorOptions={this.props.colorOptions}
            />
          })
        }
      </div>
    } else {
      answers = <div>
        {
          this.props.answers.map( (answer, id) => {
            return <EditSingleAnswer
              key={id}
              answerPos={id}
              answer={answer.answer}
              color={answer.color}
              label={answer.label}
              colorOptions={this.props.colorOptions}
              labelOptions={this.props.labelOptions}
              onUpdateInternalAnswer={(pos, e) => this.onUpdateInternalAnswer(pos, e)}
            />
          })
        }
      </div>
    }

    return (
      <tr>
        <td>{this.props.questionId}</td>
        <td>{answers}</td>
        <td>
          {!this.state.editMode && <button 
            key={this.props.questionId} 
            onClick={() => this.startEditMode()}
            className="btn btn-secondary">Edit
          </button>
          }
          { this.state.editMode && <div>
            <button
              className="btn btn-secondary"
              onClick={() => this.stopEditMode()}
            >Cancel</button>
          </div>
          }
        </td>
      </tr>
    );

  }
}
