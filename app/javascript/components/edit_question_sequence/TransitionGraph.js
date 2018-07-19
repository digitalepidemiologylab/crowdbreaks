
import React from 'react'
import PropTypes from 'prop-types';

// Other
import { Graph  } from 'react-d3-graph';

export class TransitionGraph extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
    };
  }

  generateGraph() {
    var transitions = {};
    var nodes_arr = []
    for (let id in this.props.transitions) {
      let from_question = this.props.transitions[id].from_question;
      let to_question = this.props.transitions[id].transition.to_question;
      if (from_question in transitions) {
        if (!(transitions[from_question].includes(to_question)))  {
          transitions[from_question].push(to_question)
        }
      } else {
        transitions[from_question] = [to_question]
      }
      if (!(nodes_arr.includes(from_question))) {
        nodes_arr.push(from_question)
      }
      if (!(nodes_arr.includes(to_question))) {
        nodes_arr.push(to_question)
      }
    }

    // collect nodes
    var nodes = [{id: 'end'}];
    for (let i in nodes_arr) {
      nodes.push({id: nodes_arr[i].toString()})
      if (!(nodes_arr[i] in transitions)) {
        transitions[nodes_arr[i]] = ['end']
      }
    }
    
    // collect links
    var links = [];
    for (let i in transitions) {
      for (let j in transitions[i]) {
        links.push({source: i, target: transitions[i][j].toString()})
      }
    }
    return {nodes: nodes, links: links}
  }

  render() {
    var data = this.generateGraph();
    const color = '#212529';
    const highlightColor = '#db4457';
    const fontSize = 14;
    const myConfig = {
      nodeHighlightBehavior: true,
      node: {
        color: color,
        fontSize: fontSize,
        fontColor: color,
        size: 200,
        highlightStrokeColor: highlightColor,
        highlightColor: highlightColor,
        highlightFontSize: fontSize
      },
      link: {
        color: color,
        highlightColor: highlightColor
      },
      height: 300,
      width: 908
    };

    return (
      <div 
        style={{width: '100%', height: '300px', border: '1px solid #808080'}}>
        <Graph 
          id="question-sequence-graph"
          data={data}
          config={myConfig}
        />
      </div>
    )
  }
}
