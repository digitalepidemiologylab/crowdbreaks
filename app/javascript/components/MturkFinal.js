import React from 'react'
import PropTypes from 'prop-types';

export const MturkFinal = (props) => {
  return (
    <div className='final content-no-banner'>
      <h1>{props.translations.final.thank_you}</h1>
    </div>
  );
};

MturkFinal.propTypes = {
  translations: PropTypes.object
};
