// React
import React from 'react'

// Other 
var humps = require('humps');

// Components
import { QuestionSequence } from './QuestionSequence';
import { MturkFinal } from './MturkFinal';
import { Instructions } from './Instructions';

export class MturkQSContainer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      'tweetLoadError': false,
      'questionSequenceHasEnded': false,
      'errors': [],
      'results': [],
      'displayInstructions': false,
      'logs': {}
    };
  }

  submitResult(resultData) {
    // Single answer submit hook, do nothing
    return true;
  }

  onTweetLoadError() {
    this.setState({
      errors: this.state.errors.concat(['Error when trying to load tweet. Ensure you disable browser plugins which may block this content.'])
    });
  }

  onQuestionSequenceEnd(results, logs) {
    // Set final state which gets submitted in onSubmit()
    this.setState({
      'questionSequenceHasEnded': true,
      'results': results,
      'logs': logs
    });
  }

  logSubmit() {
    let newLog = this.state.logs;
    const now = this.getTime();
    newLog['totalDurationUntilMturkSubmit'] = now - newLog['timeMounted'];
    newLog['timeMturkSubmit'] = now;
    this.setState({
      logs: newLog
    });
  }

  onSubmit(event) {
    event.preventDefault();

    if (this.props.testMode) {
      alert('No submit possible, since you are running in test mode.')
      return true;
    }

    var taskUpdate = humps.decamelizeKeys({
      task: {
        'workerId': this.props.workerId,
        'assignmentId': this.props.assignmentId,
        'tweetId': this.props.tweetId,
        'hitId': this.props.hitId,
        'results': this.state.results
      }
    });
    // Add uncamelized logs
    this.logSubmit()
    taskUpdate['task']['logs'] = this.state.logs

    $.ajax({
      type: "POST",
      url: this.props.finalSubmitPath,
      data: JSON.stringify(taskUpdate),
      contentType: "application/json",
      success: (response) => {
        console.log('success')
        $('#submit-form').submit();
        return true;
      },
      error: (response) => {
        this.setState({
          errors: this.state.errors.concat([response.statusText])
        });
        // Give reward anyway (!)
        $('#submit-form').submit();
        return true;
      }
    });
  }

  getSubmitUrl() {
    var sandbox_prefix = this.props.sandbox ? 'workersandbox' : 'www';
    return "https://" + sandbox_prefix + ".mturk.com/mturk/externalSubmit";
  }

  onToggleInstructionDisplay() {
    this.setState({
      displayInstructions: !this.state.displayInstructions
    })
  }

  onRestart() {
    if (!this.props.allowReset) {
      alert('Reset not allowed.')
      return
    }
    if (confirm('Are you sure you want to restart the task? All previous answers given will be deleted.')) {
      if (!this.state.questionSequenceHasEnded && !this.props.noWorkAvailable) {
        this.questionSequence.restartQuestionSequence()
      }
      this.setState({
        results: [],
        errors: [],
        logs: [],
        questionSequenceHasEnded: false
      })
    }
  }

  onHelp() {
    window.location.href= 'mailto:'.concat(this.props.helpEmail,  
      '?subject=Mturk worker question, hitId=', this.props.hitId)
  }

  getOptionButtons() {
    if (this.props.previewMode) {
      return;
    }
    return <div className='mb-5 buttons'>
      {this.props.allowReset && <button 
          onClick={() => this.onRestart()}
          className='btn btn-secondary'>
          <i className='fa fa-refresh' style={{color: '#212529'}}></i>&emsp;Restart
        </button>}
      <button 
        onClick={() => this.onHelp()}
        className='btn btn-secondary'>
        <i className='fa fa-question-circle' style={{color: '#212529'}}></i>&emsp;Ask for help
      </button>
    </div>
  }

  getPreviewText() {
    return <div>
      <p>Please accept the HIT to start working on it.</p>
    </div>
  }

  getNoWorkAvailableText() {
    return <div>
      <h3>You have completed all work in this HIT group.</h3>
      <p style={{color: "red"}}>This HIT and future HITs in this group can not be completed. We kindly ask you to return the HIT.</p>
    </div>

  }

  getQuestionSequence() {
    if (this.props.previewMode) {
      return this.getPreviewText()
    }
    if (this.props.noWorkAvailable) {
      return this.getNoWorkAvailableText()
    }
    if (!this.state.questionSequenceHasEnded) {
      return <QuestionSequence 
        ref={qs => {this.questionSequence = qs;}}
        initialQuestionId={this.props.initialQuestionId}
        questions={this.props.questions}
        transitions={this.props.transitions}
        tweetId={this.props.tweetId}
        userId={null}
        projectId={this.props.projectId}
        submitResult={(args) => this.submitResult(args)}
        onTweetLoadError={() => this.onTweetLoadError()}
        onQuestionSequenceEnd={(results, logs) => this.onQuestionSequenceEnd(results, logs)}
        numTransitions={0}
        captchaVerified={true}
        enableAnswersDelay={this.props.enableAnswersDelay}
        displayQuestionInstructions={true}
      /> 
    } else {
      return <MturkFinal 
        onSubmit={(event) => this.onSubmit(event)}
        submitUrl={this.getSubmitUrl()}
        assignmentId={this.props.assignmentId}
        hitId={this.props.hitId}
      /> 
    }
  }

  render() {
    let title = this.props.mturkTitle && <h4 className="mb-4">
      {this.props.mturkTitle}
    </h4>;
    let mturkInstructions = <Instructions 
      display={this.state.displayInstructions || this.props.previewMode}
      instructions={this.props.instructions}
      onToggleDisplay={() => this.onToggleInstructionDisplay()}
    />;
    let body = this.getQuestionSequence()
    let optionButtons = this.getOptionButtons()
    let errors = this.state.errors.length > 0 && <ul className='qs-error-notifications'>
      <li>Error:</li>
      {this.state.errors.map(function(error, i) {
        return <li key={i}>{error}</li>
      })}
    </ul>
      return(
        <div className="QSContainer" style={{paddingTop: '30px'}}>
          {title}
          {mturkInstructions} 
          {optionButtons}
          {errors}
          {body}
        </div>
      );
  }
}
