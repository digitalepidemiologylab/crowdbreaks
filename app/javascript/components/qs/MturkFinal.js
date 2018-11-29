import React from 'react'
import PropTypes from 'prop-types';
import { ClipLoader } from 'react-spinners';

export class MturkFinal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      btnDisabled: false,
      submitting: false
    }
  }

  onFormSubmit(e, time) {
    // e.persist();
    e.preventDefault();
    $('#submit-form').hide();
    this.setState({
      btnDisabled: true,
      submitting: true
    }, () => {
      this.props.onMturkSubmit(time);
    })
  }

  render() {
    console.log(this.props)
    return (
      <div className='row justify-content-center'> 
        <div className="col-12">
          <div className='mb-5'>
            <h3>Thank you for your help.</h3>
            <p>Please click the button below to submit the HIT and claim your reward.</p>
          </div>
          { 
            this.state.submitting &&
              <div>
                <div className="clip-loader">
                  <ClipLoader
                    color={'#444'} 
                  />
                </div>
                <div>
                  Submitting... Please wait
                </div>
              </div>
          } 
          <div className='mb-5'>
            <form onSubmit={(e) => this.onFormSubmit(e, new Date().getTime())} id="submit-form" action={this.props.submitUrl}>
              <input type="hidden" name="assignmentId" value={this.props.assignmentId} />
              <input type="hidden" name="hitId" value={this.props.hitId} />
              <input type="hidden" name="dummy" value="dummyvalue" />
              <input type="submit" name="Submit" id="submitButton" className="btn btn-primary btn-lg" disabled={this.state.btnDisabled}/>
            </form>
          </div>
        </div>
      </div>
    );
  }
};

MturkFinal.propTypes = {
  onMturkSubmit: PropTypes.func,
  submitUrl: PropTypes.string,
  assignmentId: PropTypes.string,
  hitId: PropTypes.string
};
