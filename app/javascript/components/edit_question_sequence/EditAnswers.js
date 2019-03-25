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
    let dummyAnswers = this.props.answers;
    dummyAnswers[e.answerPos].answer = e.answer;
    dummyAnswers[e.answerPos].color = e.color;
    dummyAnswers[e.answerPos].label = e.label;
    dummyAnswers[e.answerPos].tag = e.tag;
    this.props.onUpdateAnswers({'answers': dummyAnswers, 'questionId': this.props.questionId})
    this.stopEditMode();
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
      answers = <div className='mb-5'>
        <div className='mb-5'>
        {
          this.props.answers.map( (answer, id) => {
            return <EditSingleAnswer
              key={id}
              answerPos={id}
              answerId={answer.id}
              answer={answer.answer}
              color={answer.color}
              label={answer.label}
              tag={answer.tag}
              colorOptions={this.props.colorOptions}
              labelOptions={this.props.labelOptions}
              questionId={this.props.questionId}
              isEditable={this.props.isEditable}
              onUpdateInternalAnswer={(e) => this.onUpdateInternalAnswer(e)}
              onDeleteAnswer={this.props.onDeleteAnswer}
            />
          })
        }
      </div>
      <div>
        {this.props.isEditable && <button 
          onClick={() => this.props.addNewAnswer(this.props.questionId)} 
          className='btn btn-primary'>
          <i className='fa fa-plus' style={{color: '#fff'}}></i>&emsp;Add new answer
        </button>}
      </div>
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
