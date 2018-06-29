import React from 'react'

export class EditSingleAnswer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      answer: props.answer,
      color: props.color,
      label: props.label,
      changed: false
    };
  }

  onUpdateAnswer(e) {
    this.setState({answer: e.target.value, changed: true})
  }

  onUpdateLabel(e) {
    this.setState({label: e.target.value, changed: true})
  }

  onUpdateColor(e) {
    this.setState({color: e.target.value, changed: true})
  }

  onUpdate() {
    this.props.onUpdateInternalAnswer({'answerPos': this.props.answerPos, 'label': this.state.label, 'color': this.state.color, 'answer': this.state.answer})
  }

  render() {
    const componentsStyle = {display: 'inline-block', marginRight: '10px', marginBottom: '10px'}
    const answerStyle = {...componentsStyle, width: '40%'}
    const selectStyle = {...componentsStyle, width: '20%'}

    let updateButton = this.state.changed && <button 
      className='btn btn-primary'
      onClick={() => this.onUpdate()}
      >Update</button>
    return (
      <div>
        <div style={answerStyle}>
          <input 
            value={this.state.answer}
            onChange={(e) => this.onUpdateAnswer(e)}
            className='form-control'>
          </input>
        </div>
        <div style={selectStyle}>
          <select 
            className='form-control' 
            value={this.state.color}
            onChange={(e) => this.onUpdateColor(e)}>
            {
              Object.keys(this.props.colorOptions).map( (label, i) => {
                return(<option key={i} value={label}>{label}</option>)
              })
            }
          </select>
        </div>
        <div style={selectStyle}>
          <select 
            className='form-control' 
            value={this.state.label}
            onChange={(e) => this.onUpdateLabel(e)}>
            {
              this.props.labelOptions.map( (label, i) => {
                return(<option key={i} value={label}>{label}</option>)
              })
            }
          </select>
        </div>
        {updateButton}
      </div>
    );
  }
};
