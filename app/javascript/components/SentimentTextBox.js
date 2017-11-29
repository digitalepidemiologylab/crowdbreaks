// React
import React from 'react'
import PropTypes from 'prop-types';
import { ExampleInput } from './../components/ExampleInput';

export class SentimentTextBox extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      'textValue': "",
      'label': 'undetermined'
    };
  }


  onHandleChange(value) {
    var data = {"text": value};
    let newLabel = this.state.label;
    this.setState({
      'textValue': value,
    });
    if (value == '' || value.trim().split(' ').length <= 2) {
      this.setState({'label': 'undetermined'});
      return
    }

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
        console.log(result);
        this.setState({label: result['label']});
      }
    });
  }

  onExampleClick(exampleText) {
    $('#inputTextField').val(exampleText);
    this.onHandleChange(exampleText);
  }
  

  render() {
    const examples = [
      'You should vaccinate your kids', 
      'You shouldn\'t vaccinate your kids',
      'Make sure to get vaccinated',
      'Time to get vaccinated',
      'The WHO recommends vaccination',
      'Vaccines cause autism',
      'All vaccines cause autism'
    ];
    var parentThis = this;
    var color = { 'undetermined': 'grey', 'pro-vaccine': 'green', 'anti-vaccine': 'red', 'other': 'grey' }[this.state.label];
    var labelStyle = {
      color: color
    }

    return(
      <div>
        <h4>Type something (at least 3 words)</h4>
        <textarea 
          id="inputTextField"
          type="text" 
          value={this.state.textValue}
          onChange={changeEvent => this.onHandleChange(changeEvent.target.value)}
          className="form-control"
        />
        <h2 style={labelStyle}>{this.state.label}</h2>
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
