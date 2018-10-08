import React from 'react'

export class EditSingleAnswer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      answer: props.answer,
      color: props.color,
      label: props.label
    };
  }

  onUpdateAnswer(e) {
    this.setState({answer: e.target.value})
  }

  onUpdateLabel(e) {
    this.setState({label: e.target.value})
  }

  onUpdateColor(e) {
    this.setState({color: e.target.value})
  }

  onUpdate() {
    this.props.onUpdateInternalAnswer({'answerPos': this.props.answerPos, 'label': this.state.label, 'color': this.state.color, 'answer': this.state.answer})
  }

  render() {
    const componentsStyle = {display: 'inline-block', marginRight: '10px', marginBottom: '10px'}
    const idStyle = {...componentsStyle, width: '5%'}
    const answerStyle = {...componentsStyle, width: '35%'}
    const selectStyle = {...componentsStyle, width: '15%'}
    const buttonStyle = {margin: '10px 10px 10px 0px'}

    let updateButton = <button 
      className='btn btn-primary'
      style={buttonStyle}
      onClick={() => this.onUpdate()}
      >OK</button>
    return (
      <div className='mb-4'>
        <div style={idStyle}>
          {this.props.answerId}
        </div>
        <div style={answerStyle}>
          <input 
            value={this.state.answer}
            disabled={this.props.isEditable ? false : 'disabled'}
            onChange={(e) => this.onUpdateAnswer(e)}
            className='form-control'>
          </input>
        </div>
        <div style={selectStyle}>
          <select 
            className='form-control' 
            value={this.state.color}
            disabled={this.props.isEditable ? false : 'disabled'}
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
            disabled={this.props.isEditable ? false : 'disabled'}
            onChange={(e) => this.onUpdateLabel(e)}>
            {
              this.props.labelOptions.map( (label, i) => {
                return(<option key={i} value={label}>{label}</option>)
              })
            }
          </select>
        </div>
        {this.props.isEditable && updateButton}
        {this.props.isEditable && <button 
          onClick={(e) => this.props.onDeleteAnswer(this.props.answerId, this.props.questionId, e)}
          style={buttonStyle}
          className="btn btn-negative">Delete
        </button>}
      </div>
    );
  }
};
