// React
import React from 'react'
import PropTypes from 'prop-types';
import { ExampleInput } from './ExampleInput';

export class SentimentTextBox extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      'textValue': "",
      'label': 'undetermined',
      'pro_vaccine': 0, 
      'neutral': 0, 
      'anti_vaccine': 0
    };
    this.num_words = 0;
  }

  onHandleChange(value) {
    var data = {"text": value};
    let newLabel = this.state.label;
    this.setState({
      'textValue': value,
    });
    var input_num_words = value.trim().split(' ').length
    if (value == '' || input_num_words <= 2) {
      this.setState({'label': 'undetermined'});
      return
    }
    
    // only update once new word has been typed
    if (this.num_words == input_num_words) {
      return
    }
    this.num_words = input_num_words;

    $.ajax({
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      type: "POST",
      crossDomain: true,
      url: this.props.flaskPostEndpoint,
      data: JSON.stringify(data),
      dataType: "json",
      contentType: "application/json",
      success: (result) => {
        result = JSON.parse(result);
        var p_vals = {}
        for (var i=0; i<result['labels'].length; i++) {
          p_vals[result['labels'][i]] = result['probabilities'][i];
        }
        console.log('Received label '+result['labels'][0]);
        this.setState({
          'label': result['labels'][0],
          'pro_vaccine': p_vals['pro-vaccine'],
          'anti_vaccine': p_vals['anti-vaccine'],
          'neutral': p_vals['neutral']
        });
      }
    });
  }

  onExampleClick(exampleText) {
    $('#inputTextField').val(exampleText);
    this.onHandleChange(exampleText);
  }

  round(input, precision=3) {
    var factor = Math.pow(10, precision)
    var res = Math.round(input*100*factor)/factor 
    if (res>100.0) {
      return 100;
    } else {
      return res;
    }
  }
  

  render() {
    const examples = [
      'You should vaccinate your kids', 
      'You shouldn\'t vaccinate your kids',
      'Make sure to get vaccinated',
      'Time to get vaccinated',
      'The WHO recommends vaccination',
      'Vaccines are the cause of cause autism',
      'Vaccines are evil',
      'My child was diagnosed with autism after vaccination'
    ];
    var parentThis = this;
    var color = { 'undetermined': 'grey', 'pro-vaccine': 'green', 'anti-vaccine': 'red', 'other': 'grey' }[this.state.label];
    var labelStyle = {
      color: color
    }

    return(
      <div>
        <div className="mb-5">
          <h4>Type something (at least 3 words)</h4>
          <textarea 
            id="inputTextField"
            type="text" 
            value={this.state.textValue}
            onChange={changeEvent => this.onHandleChange(changeEvent.target.value)}
            className="form-control"
          />
          <h2 style={labelStyle}>{this.state.label}</h2>
          <span>Pro-vaccine ({this.round(this.state.pro_vaccine)}%), Neutral ({this.round(this.state.neutral)}%), Anti-vaccine ({this.round(this.state.anti_vaccine)}%)</span>
        </div>
        <h3>Test examples:</h3>
        {examples.map(function(ex) {
          return <ExampleInput key={ex} onExampleClick={() => parentThis.onExampleClick(ex)} exampleText={ex}/>
        })}
      </div>
    )
  }
}


SentimentTextBox.propTypes = {
  flaskPostEndpoint: PropTypes.string
}
