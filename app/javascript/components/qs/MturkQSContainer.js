// React
import React from 'react'

// Other 
var humps = require('humps');

// Components
import { QuestionSequence } from './QuestionSequence';
import { MturkFinal } from './MturkFinal';
import { MturkInstructions } from './MturkInstructions';

export class MturkQSContainer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      'tweetLoadError': false,
      'questionSequenceHasEnded': false,
      'errors': [],
      'results': [],
      'displayInstructions': false
    };
  }

  postData(resultData) {
    // Do not post anything in preview mode
    if (this.props.previewMode) {
      console.log('Cannot submit in preview mode');
      return false;
    }
    // Do not post anything if tweet could not be loaded properly
    if (this.state.tweetLoadError) {
      console.log('Cannot submit when Tweet loading failed');
      return false;
    }

    // In reset mode, collect results but do not post yet
    if (this.props.allowReset) {
      this.setState({
        results: this.state.results.concat([resultData])
      })
      return true;
    }

    // In test mode do not collect any results
    if (this.props.testMode) {
      return true;
    }

    // Post single result
    resultData['hit_id'] = this.props.hitId;
    $.ajax({
      type: "POST",
      url: this.props.resultsPath,
      data: JSON.stringify(resultData),
      contentType: "application/json",
      success: (response) => {
        console.log('Successfully transmitted single result.')
        return
      },
      error: (response) => {
        console.log('Error when transmitting single result.')
        this.setState({
          errors: this.state.errors.concat(['Internal error'])
        });
        return
      }
    });
    // Continue even on error
    return true;
  }

  onTweetLoadError() {
    // Todo: handle exception
    this.setState({
      errors: this.state.errors.concat(['Tweet not available anymore'])
    });
  }

  onQuestionSequenceEnd() {
    console.log("Question sequence ended!");
    this.setState({
      'questionSequenceHasEnded': true
    });
  }

  onSubmit(event) {
    event.preventDefault();

    if (this.props.testMode) {
      alert('No submit since running in test mode.')
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
    if (confirm('Are you sure you want to restart the task? All previous answers given will be deleted.')) {
      if (!this.state.questionSequenceHasEnded) {
        this.questionSequence.restartQuestionSequence()
      }
      this.setState({
        results: [],
        errors: [],
        questionSequenceHasEnded: false
      })
    }
  }

  test1() {
    var resultData = humps.decamelizeKeys({
      result: {
        answerId: 0,
        questionId: 0,
        userId: this.props.userId,
        tweetId: this.props.tweetId,
        projectId: this.props.projectId
      }
    });
    $.ajax({
      type: "POST",
      url: this.props.resultsPath,
      data: JSON.stringify(resultData),
      contentType: "application/json",
      success: (response) => {
        console.log('success')
        return
      },
      error: (response) => {
        console.log('error')
        this.setState({
          errors: this.state.errors.concat(['Internal error'])
        });
        return
      }
    });
  }

  test2() {
    var taskUpdate = humps.decamelizeKeys({
      task: {
        'workerId': 0,
        'assignmentId': this.props.assignmentId,
        'tweetId': this.props.tweetId,
        'hitId': this.props.hitId,
        'results': this.state.results
      }
    });

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

  onHelp() {
    window.location.href= 'mailto:'.concat(this.props.helpEmail,  
      '?subject=Mturk worker question, hitId=', this.props.hitId)
  }

  render() {
    console.log(this.state.results)
    let body;
    let title = this.props.mturkTitle && <h4 className="mb-4">{this.props.mturkTitle}</h4> 
    let mturkInstructions = <MturkInstructions 
      display={this.state.displayInstructions}
      instructions={this.props.instructions}
      onToggleDisplay={() => this.onToggleInstructionDisplay()}/>
    let optionButtons = <div className='mb-5 buttons'>
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
      {
        this.props.testMode && <button 
            onClick={() => this.test1()}
            className='btn btn-secondary'>
            Test Results path
          </button>
      } {
        this.props.testMode && <button 
            onClick={() => this.test2()}
            className='btn btn-secondary'>
            Test Final path
          </button>
      }
    </div>
    if (!this.state.questionSequenceHasEnded) {
      body = <QuestionSequence 
        ref={qs => {this.questionSequence = qs;}}
        initialQuestionId={this.props.initialQuestionId}
        questions={this.props.questions}
        transitions={this.props.transitions}
        tweetId={this.props.tweetId}
        userId={null}
        projectId={this.props.projectId}
        postData={(args) => this.postData(args)}
        onTweetLoadError={() => this.onTweetLoadError()}
        onQuestionSequenceEnd={() => this.onQuestionSequenceEnd()}
        numTransitions={0}
        captchaVerified={true}
        enableAnswersDelay={this.props.enableAnswersDelay}
        displayQuestionInstructions={true}
      /> 
    } else {
      body = <MturkFinal 
        onSubmit={(event) => this.onSubmit(event)}
        submitUrl={this.getSubmitUrl()}
        assignmentId={this.props.assignmentId}
        hitId={this.props.hitId}
      /> 
    }
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
