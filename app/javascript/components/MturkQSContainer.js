// React
import React from 'react'
import PropTypes from 'prop-types';

// Components
import { QuestionSequence } from './../components/QuestionSequence';

export class MturkQSContainer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      'tweetLoadError': false
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
    resultData['assignment_id'] = this.props.assignmentId;
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

  
  render() {
    return(
      <QuestionSequence 
        initialQuestionId={this.props.initialQuestionId}
        questions={this.props.questions}
        transitions={this.props.transitions}
        tweetId={this.props.tweetId}
        projectsPath={this.props.projectsPath}
        translations={this.props.translations}
        userId={this.props.userId}
        projectId={this.props.projectId}
        postData={(args) => this.postData(args)}
        onTweetLoadError={() => this.onTweetLoadError()}
      />); 
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
  previewMode: PropTypes.bool
}
