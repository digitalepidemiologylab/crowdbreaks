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
      'labels': [],
      'probabilities': []
    };
    this.num_words = 0;
  }

  onHandleChange(value) {
    let data = {"text": value};
    this.setState({
      'textValue': value,
    });
    const input_num_words = value.trim().split(' ').length
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
        let prediction = result['prediction']
        this.setState({
          'label': prediction['labels'][0],
          'labels': prediction['labels'],
          'probabilities': prediction['probabilities'],
        });
      }
    });
  }

  onExampleClick(exampleText) {
    $('#inputTextField').val(exampleText);
    this.onHandleChange(exampleText);
  }

  round(input, precision=3) {
    const factor = Math.pow(10, precision)
    const res = Math.round(input*100*factor)/factor
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
    let parentThis = this;
    const color = { 'undetermined': 'grey', 'pro-vaccine': 'green', 'anti-vaccine': 'red', 'other': 'grey' }[this.state.label];
    const labelStyle = {
      color: color
    }
    let probabilities = <ul>
        {this.state.labels.map((label, i) => {
          return <li key={i}>{label} ({this.round(this.state.probabilities[i])}%)</li>
        })}
    </ul>;

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

          <div className="mt-3">
            <h2 style={labelStyle}>{this.state.label}</h2>
            {probabilities}
          </div>
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
