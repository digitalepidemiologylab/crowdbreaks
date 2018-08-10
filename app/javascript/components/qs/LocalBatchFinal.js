import React from 'react'
import PropTypes from 'prop-types';

export const LocalBatchFinal = (props) => {
  return (
    <div>
      <div className="row justify-content-center">
        <div className="col-12 col-sm-10 col-lg-6 text-center">
          <h1 className="mb-4">Thanks for your help!</h1>
          <p className='large text-light mb-4'></p>
        </div>
      </div>

      <div className="row justify-content-center">
        <div className="col-12 col-sm-10 col-lg-5 text-center">
          <div className="buttons-fluid">
            <button onClick={ props.onNextQuestionSequence } className='btn btn-primary btn-lg' style={{marginRight: '12px'}}>
              Continue
            </button>
            <a href={props.exitPath} className='btn btn-secondary btn-lg'>
              Exit
            </a>
          </div>
        </div>
      </div>
    </div>
  );
};

export const LocalBatchNoMoreWork = (props) => {
  return (
    <div>
      <div className="row justify-content-center">
        <div className="col-12 col-sm-10 col-lg-6 text-center">
          <h1 className="mb-4">Thanks! You have finished all {props.totalCount} tweets in this batch.</h1>
          <p className='large text-light mb-4'></p>
        </div>
      </div>

      <div className="row justify-content-center">
        <div className="col-12 col-sm-10 col-lg-5 text-center">
          <div className="buttons-fluid">
            <a href={props.exitPath} className='btn btn-secondary btn-lg'>
              Exit
            </a>
          </div>
        </div>
      </div>
    </div>
  );
};
