// React
import React from 'react'
import PropTypes from 'prop-types';

// Other 
var humps = require('humps');

// Components
import { QuestionSequence } from './QuestionSequence';
import { MturkFinal } from './MturkFinal';

export class MturkQSContainer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      'tweetLoadError': false,
      'questionSequenceHasEnded': false
    };
  }

  postData(resultData) {
    if (this.props.previewMode) {
      console.log('Cannot submit in preview mode');
      return false;
    }
    if (this.state.tweetLoadError) {
      console.log('Cannot submit when Tweet loading failed');
      return false;
    }
    resultData['hit_id'] = this.props.hitId;
    $.ajax({
      type: "POST",
      url: this.props.resultsPath,
      data: resultData,
    });
    return true;
  }

  onTweetLoadError() {
    // Todo: handle exception
    console.log("Tweet not available anymore");
    this.setState({
      'tweetLoadError': true
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

    var taskUpdate = humps.decamelizeKeys({
      task: {
        'workerId': 0,
        'assignmentId': this.props.assignmentId,
        'tweetId': this.props.tweetId,
        'hitId': this.props.hitId
      }
    });

    $.ajax({
      type: "POST",
      url: this.props.finalSubmitPath,
      data: taskUpdate,
      success: function(result) {
        alert('Form submitted successfully');
        $('#submit-form').submit();
        return true;
      }
    });
  }

  getSubmitUrl() {
    var sandbox_prefix = this.props.sandbox ? 'workersandbox' : 'www';
    return "https://" + sandbox_prefix + ".mturk.com/mturk/externalSubmit";
  }

  render() {
    let body = null;
    if (!this.state.questionSequenceHasEnded) {
      body = <QuestionSequence 
        initialQuestionId={this.props.initialQuestionId}
        questions={this.props.questions}
        transitions={this.props.transitions}
        tweetId={this.props.tweetId}
        userId={this.props.userId}
        projectId={this.props.projectId}
        postData={(args) => this.postData(args)}
        onTweetLoadError={() => this.onTweetLoadError()}
        onQuestionSequenceEnd={() => this.onQuestionSequenceEnd()}
      /> 
    } else {
      body = <MturkFinal 
        onSubmit={(event) => this.onSubmit(event)}
        submitUrl={this.getSubmitUrl()}
        assignmentId={this.props.assignmentId}
        hitId={this.props.hitId}
      /> 
    }
    return(
      <div className="QSContainer">
        {body}
      </div>
    );
  }
}

MturkQSContainer.propTypes = {
  initialQuestionId: PropTypes.number,
  questions: PropTypes.object,
  transitions: PropTypes.object,
  tweetId: PropTypes.string,
  projectsPath: PropTypes.string,
  resultsPath: PropTypes.string,
  translations: PropTypes.object,
  userId: PropTypes.number,
  projectId: PropTypes.number,
  assignmentId: PropTypes.string,
  previewMode: PropTypes.bool,
  sandbox: PropTypes.bool,
  finalSubmitPath: PropTypes.string,
  hitId: PropTypes.string
}
