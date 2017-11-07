import React from 'react'
import PropTypes from 'prop-types';

export const MturkFinal = (props) => {
  return (
    <div className='final content-no-banner'>
      <h3>Thank you for your help.</h3>
      <p>Please click the button below to submit the HIT.</p>

      <form onSubmit={props.onSubmit} id="submit-form" action={props.submitUrl}>
        <input type="hidden" name="assignmentId" value={props.assignmentId} />
        <input type="submit" name="Submit" id="submitButton" className="btn btn-final"/>
      </form>
    </div>
  );
};

MturkFinal.propTypes = {
  onSubmit: PropTypes.func,
  submitUrl: PropTypes.string,
  assignmentId: PropTypes.string
};
