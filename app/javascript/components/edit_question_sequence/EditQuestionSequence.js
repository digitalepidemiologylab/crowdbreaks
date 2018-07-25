// React
import React from 'react'

// Sub-components
import { EditQuestion } from './EditQuestion';
import { EditAnswers } from './EditAnswers';
import { EditTransition } from './EditTransition';
import { TransitionGraph } from './TransitionGraph';

// Other
import { ClipLoader } from 'react-spinners';

export class EditQuestionSequence extends React.Component {
  constructor(props) {
    super(props);

    let questions = props.questions;
    if (Object.keys(props.questions).length == 0) {
      questions[0]  = {id: 0, question: '', answers: []}
    }
    let transitions = props.transitions;
    if (Object.keys(props.transitions).length == 0) {
      transitions[0]  = {id: 0, from_question: 'start', transition: {to_question: 0, answer: ''}}
    }

    this.state = {
      questions: questions,
      transitions: transitions,
      showQuestions: false,
      showAnswers: false,
      showTransitions: false,
      newQuestionIdCounter: Math.max( ...Object.keys(questions).map(Number)) + 1,
      newTransitionIdCounter: Math.max( ...Object.keys(props.transitions).map(Number)) + 1,
      newAnswerIdCounter: this.findMaxAnswerId(questions) + 1,
      isLoading: false,
      errors: []
    };
  }

  findMaxAnswerId(questions) {
    let answerIds = [0];
    for (let questionId in questions) {
      for (let answerId in questions[questionId].answers) {
        answerIds.push(questions[questionId].answers[answerId].id)
      }
    }
    return Math.max(...answerIds)
  }

  onUpdateQuestion(e) {
    var dummyQuestion = this.state.questions;
    dummyQuestion[e.id].question = e.question;
    dummyQuestion[e.id].instructions = e.instructions;
    this.setState({
      questions: dummyQuestion,
    })
  }

  onUpdateAnswers(e) {
    var dummyQuestions = this.state.questions;
    dummyQuestions[e.questionId].answers = e.answers;
    this.setState({
      questions: dummyQuestions,
    })
  }

  onUpdateTransition(e) {
    var dummyTransition = this.state.transitions;
    dummyTransition[e.id].from_question = e.from_question;
    dummyTransition[e.id].transition.to_question = e.transition.to_question;
    dummyTransition[e.id].transition.answer = e.transition.answer;
    this.setState({
      transitions: dummyTransition,
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
      case 'transitions':
        this.setState({
          showTransitions: !this.state.showTransitions
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

  addNewQuestion() {
    let newQuestions = this.state.questions;
    newQuestions[this.state.newQuestionIdCounter] = {id: this.state.newQuestionIdCounter, question: '', answers: []}
    this.setState({
      questions: newQuestions,
      newQuestionIdCounter: this.state.newQuestionIdCounter + 1
    })
  }

  addNewAnswer(questionId) {
    var dummyQuestions = this.state.questions;
    dummyQuestions[questionId].answers.push({'id': this.state.newAnswerIdCounter, 'answer': '', 'color': 'btn-primary', 'label': ''})
    this.setState({
      questions: dummyQuestions,
      newAnswerIdCounter: this.state.newAnswerIdCounter + 1
    })
  }

  addNewTransition() {
    let newTransition = this.state.transitions;
    newTransition[this.state.newTransitionIdCounter] = {id: this.state.newTransitionIdCounter, from_question: '', transition: {to_question: '', answer: ''}}
    this.setState({
      transitions: newTransition,
      newTransitionIdCounter: this.state.newTransitionIdCounter + 1
    })
  }

  onDeleteQuestion(questionId, e) {
    let newQuestions = this.state.questions;
    delete newQuestions[questionId]
    this.setState({
      questions: newQuestions
    })
  }

  onDeleteAnswer(answerId, questionId, e) {
    var newAnswers = [];
    var oldAnswers = this.state.questions[questionId].answers;
    var newQuestions = this.state.questions;
    for (let answerPos in oldAnswers) {
      if (answerId != oldAnswers[answerPos].id) {
        newAnswers.push(oldAnswers[answerPos])
      }
    }
    newQuestions[questionId].answers = newAnswers;
    this.setState({
      questions: newQuestions
    })
  }

  onDeleteTransition(transitionId, e) {
    let newTransitions = this.state.transitions;
    delete newTransitions[transitionId]
    this.setState({
      transitions: newTransitions
    })
  }

  validateTransition(transition) {
    if (!(transition.from_question in this.state.questions)) {
      if (transition.from_question != 'start') {
        alert('Question Id ' + transition.from_question + ' does not exist.')
        return false
      }
    }
    if (!(transition.transition.to_question in this.state.questions)) {
      alert('Question Id ' + transition.transition.to_question + ' does not exist.')
      return false
    }
    if (transition.transition.answer != '') {
      let answers = this.state.questions[transition.from_question].answers
      let possible_answers = Object.keys(answers).map((key) => answers[key].id);
      if (!(possible_answers.includes(Number(transition.transition.answer)))) {
        alert('Answer Id ' + transition.transition.answer + ' is not a possible answer to question ' + transition.from_question)
        return false
      }
    }
    return true
  }

  saveQuestionSequence() {
    var data = {
      projectId: this.props.projectId,
      questions: this.state.questions,
      transitions: this.state.transitions
    };
    this.setState({isLoading: true});
    $.ajax({
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      type: "POST",
      crossDomain: true,
      url: this.props.saveQuestionSequencePath,
      data: JSON.stringify(data),
      contentType: "application/json",
      success: (response) => {
        this.setState({isLoading: false})
        window.location = this.props.redirectPath
      },
      error: (response) => {
        this.setState({
          isLoading: false,
          errors: this.state.errors.concat([response['statusText']])
        });
      }
    });
  }

  render() {
    var prevThis = this;
    let questionLabel = this.getLabel(this.state.showQuestions, 'Questions')
    let answersLabel = this.getLabel(this.state.showAnswers, 'Answers')
    let transitionsLabel = this.getLabel(this.state.showTransitions, 'Transitions')
    let errors = this.state.errors.length > 0 && <ul className='qs-error-notifications'>
      <li>Error:</li>
      {this.state.errors.map(function(error, i) {
        return <li key={i}>{error}</li>
      })}
    </ul>

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
          this.state.showQuestions && <div>
            <table className="table">
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
                  console.log(q)
                  return <EditQuestion 
                    key={q.id} 
                    questionId={questionId} 
                    question={q.question} 
                    instructions={q.instructions}
                    onUpdateQuestion={(e) => prevThis.onUpdateQuestion(e)}
                    onDeleteQuestion={(e) => prevThis.onDeleteQuestion(questionId, e)}
                  />
                })}
              </tbody>
            </table>
            <div className='mb-5'>
              <button 
                onClick={() => this.addNewQuestion()} 
                className='btn btn-primary btn-lg'>
                <i className='fa fa-plus' style={{color: '#fff'}}></i>&emsp;Add new question
              </button>
            </div>
          </div>
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
                onDeleteAnswer={prevThis.onDeleteAnswer.bind(prevThis)}
                addNewAnswer={(e) => prevThis.addNewAnswer(e)}
              />
            })}
          </tbody>
        </table>
        }

        {/* Transitions */}
        <div className='mb-4'>
          <button 
            onClick={() => this.toggleCheckbox('transitions')} 
            className='btn btn-secondary btn-lg btn-block'>
            {transitionsLabel}
          </button>
        </div>
        {
          this.state.showTransitions && <div className='mb-5'>

            <table className="table">
              <thead>
                <tr>
                  <th>Source ID</th>
                  <th>Target ID</th>
                  <th>Answer</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {Object.keys(this.state.transitions).map( (transitionId, id) => {
                  return <EditTransition
                    key={id}
                    sourceId={this.state.transitions[transitionId].from_question}
                    transition={this.state.transitions[transitionId].transition}
                    transitionId={transitionId}
                    onDeleteTransition={(e) => this.onDeleteTransition(transitionId, e)}
                    onUpdateTransition={(e) => this.onUpdateTransition(e)}
                    validateTransition={(e) => this.validateTransition(e)}
                  />
                })}
              </tbody>
            </table>
            <div className='mb-5'>
              <button 
                onClick={() => this.addNewTransition()} 
                className='btn btn-primary btn-lg'>
                <i className='fa fa-plus' style={{color: '#fff'}}></i>&emsp;Add new transition
              </button>
            </div>
            <TransitionGraph
              transitions={this.state.transitions}
            />
          </div>
        }
        { errors }
        { this.state.isLoading && <div className="row">
          <div className="col-12">
            <div className="clip-loader">
              <ClipLoader
                color={'#444'} 
              />
            </div>
          </div>
        </div>
        } 
        { !this.state.isLoading && <button 
          onClick={() => this.saveQuestionSequence()} 
          className='btn btn-primary btn-lg'>
          Save Question Sequence
        </button>
        }
      </div>
    )
  }
}
