import React from 'react'
import PropTypes from 'prop-types';

export const Final = (props) => {
  return (
    <div>
      <div className="row justify-content-center">
        <div className="col-12 col-sm-10 col-lg-6 text-center">
          <h1 className="mb-4">{props.translations.final.thank_you}</h1>
          <p className='large text-light mb-4'>{props.translations.final.text}</p>
        </div>
      </div>

      <div className="row justify-content-center">
        <div className="col-12 col-sm-10 col-lg-5 text-center">
          <div className="buttons-fluid">
            <button onClick={ props.onNextQuestionSequence } className='btn btn-primary btn-lg' style={{marginRight: '12px'}}>
              {props.translations.final.continue_button}
            </button>
            <a href={props.projectsPath} className='btn btn-secondary btn-lg'>
              {props.translations.final.back_to_projects_button}
            </a>
          </div>
        </div>
      </div>
    </div>
  );
};

Final.propTypes = {
  onNextQuestionSequence: PropTypes.func,
  projectsPath: PropTypes.string,
  translations: PropTypes.object
};
