// React
import React from 'react'

// Sub-components
import { EditQuestion } from './EditQuestion';
import { EditAnswers } from './EditAnswers';

export class EditQuestionSequence extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      questions: props.questions,
      showQuestions: false,
      showAnswers: false
    };
  }

  onUpdateQuestion(e) {
    console.log(e)
    var dummyQuestion = this.state.questions;
    dummyQuestion[e.id].question = e.question;
    this.setState({
      question: dummyQuestion,
    })
  }

  onUpdateAnswers(e) {
    var dummyQuestions = this.state.questions;
    dummyQuestions[e.questionId].answers = e.answers;
    this.setState({
      question: dummyQuestions,
    })
  }

  toggleCheckbox(c) {
    switch (c) {
      case 'questions':
        this.setState({
          showQuestions: !this.state.showQuestions
        });
        break;
      case 'answers':
        this.setState({
          showAnswers: !this.state.showAnswers
        });
        break;
    }
  }

  getLabel(isHidden, title) {
    let plusMinus = 'fa fa-plus'
    if (isHidden) {
      plusMinus = 'fa fa-minus'
    }
    return <div>
      <i className={plusMinus} style={{color: '#212529'}}></i>&emsp;{title}
    </div>
  }

  render() {
    const prevThis = this;
    let questionLabel = this.getLabel(this.state.showQuestions, 'Questions')
    let answersLabel = this.getLabel(this.state.showAnswers, 'Answers')

    return(
      <div>
        {/* Questions */}
        <div className='mb-4'>
          <button 
            onClick={() => this.toggleCheckbox('questions')} 
            className='btn btn-secondary btn-lg btn-block'>
            {questionLabel}
          </button>
        </div>
        {
          this.state.showQuestions && <table className="table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Question</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            {Object.keys(this.state.questions).map( (questionId, id) => {
              var q = prevThis.state.questions[questionId]
              return <EditQuestion 
                key={q.id} 
                questionId={questionId} 
                question={q.question} 
                onUpdateQuestion={(e) => prevThis.onUpdateQuestion(e)}
              />
            })}
          </tbody>
        </table>
        }
        {/* Answers */}
        <div className='mb-4'>
          <button 
            onClick={() => this.toggleCheckbox('answers')} 
            className='btn btn-secondary btn-lg btn-block'>
            {answersLabel}
          </button>
        </div>
        {
          this.state.showAnswers && <table className="table">
          <thead>
            <tr>
              <th>Question ID</th>
              <th>Answers</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            {Object.keys(this.state.questions).map( (questionId, id) => {
              var q = prevThis.state.questions[questionId]
              return <EditAnswers
                key={q.id} 
                questionId={questionId} 
                answers={q.answers} 
                colorOptions={prevThis.props.colorOptions}
                labelOptions={prevThis.props.labelOptions}
                onUpdateAnswers={(e) => prevThis.onUpdateAnswers(e)}
              />
            })}
          </tbody>
        </table>
        }
      </div>
    )
  }
}
