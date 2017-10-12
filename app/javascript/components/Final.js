import React from 'react'
import PropTypes from 'prop-types';

export const Final = (props) => {
  return (
    <div className='final'>
      <h1>{props.translations.final.thank_you}</h1>
      <a href={props.projectsPath} className='btn btn-final'>
        <i className="glyphicon glyphicon-chevron-left"/>
        {props.translations.final.back_to_projects_button}
      </a>
      <button onClick={ props.onNextQuestionSequence } className='btn btn-final'>
        {props.translations.final.continue_button}
        <i className="glyphicon glyphicon-chevron-right"/>
      </button>
    </div>
  );
};

Final.propTypes = {
  onNextQuestionSequence: PropTypes.func,
  projectsPath: PropTypes.string,
  translations: PropTypes.object
};
