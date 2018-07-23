import React from 'react'
import PropTypes from 'prop-types';

export const MturkFinal = (props) => {
  return (
    <div className='row justify-content-center'> 
      <div className="col-12">
        <div className='mb-5'>
          <h3>Thank you for your help.</h3>
          <p>Please click the button below to submit the HIT and claim your reward.</p>
        </div>

        <div className='mb-5'>
          <form onSubmit={props.onSubmit} id="submit-form" action={props.submitUrl}>
            <input type="hidden" name="assignmentId" value={props.assignmentId} />
            <input type="hidden" name="hitId" value={props.hitId} />
            <input type="hidden" name="dummy" value="dummyvalue" />
            <input type="submit" name="Submit" id="submitButton" className="btn btn-primary btn-lg"/>
          </form>
        </div>
      </div>
    </div>
  );
};

MturkFinal.propTypes = {
  onSubmit: PropTypes.func,
  submitUrl: PropTypes.string,
  assignmentId: PropTypes.string,
  hitId: PropTypes.string
};
