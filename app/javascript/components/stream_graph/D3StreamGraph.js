import * as d3 from 'd3';
import React from 'react';


export class D3StreamGraph extends React.Component {
  constructor(props) {
    super(props);
    this.margin = {top: 20, right: 0, bottom: 35, left: 5};
    this.width = this.props.width - this.margin.left - this.margin.right;
    this.height = this.props.height - this.margin.top - this.margin.bottom;
    this.keys = ['positive', 'negative', 'neutral'];
  }

  componentDidMount() {
    this.create()
  }

  componentDidUpdate() {
    this.update();
  }

  create() {
    // append the svg object to the body of the page
    let svg = d3.select(this._rootNode)
      .append("svg")
      .attr("width", this.width + this.margin.left + this.margin.right)
      .attr("height", this.height + this.margin.top + this.margin.bottom)
      .append("g")
      .attr("transform",
        "translate(" + this.margin.left + "," + this.margin.top + ")");

    let _this = this;
    svg.append('g')
      .attr('class', 'stream-data')
      .selectAll('paths')
      .data(this.stackedData())
      .enter()
      .append("path")

    // Add X axis
    svg.append("g")
      .attr('class', 'stream-graph-axis xaxis')
      .attr("transform", "translate(0," + this.height + ")")

    // Add Y axis
    svg.append("g")
      .attr('class', 'stream-graph-axis yaxis')

    this.update()
  }

  xScale() {
    return d3.scaleLinear().domain(d3.extent(this.props.data, function(d) { return d.year; })).range([0, this.width])
  }

  yScale() {
    let extent;
    switch (this.props.vizOption) {
      case 'normal':
        extent = [0, 1];
        break;
      case 'wiggle':
        extent = d3.extent(this.props.data, (d) => {
          return d3.sum([d.positive, d.negative, d.neutral])
        });
        const diff = (extent[1] - extent[0])/2 * 1.6;
        extent = [-diff, diff];
        break;
      case 'zero':
        const max = d3.max(this.props.data, (d) => {
          return d3.sum([d.positive, d.negative, d.neutral])
        });
        extent = [0, max];
        break;
    }
    return d3.scaleLinear().domain(extent).range([ this.height, 0 ]);
  }

  color() {
    return d3.scaleOrdinal().domain(this.keys).range(this.props.colors)
  }

  stackedData() {
    let offset;
    let order = d3.stackOrderNone;
    switch (this.props.vizOption) {
      case 'normal':
        offset = d3.stackOffsetExpand;
        break;
      case 'wiggle':
        offset = d3.stackOffsetSilhouette;
        break;
      case 'zero':
        offset = d3.stackOffsetNone;
        break;
    }
    return d3.stack()
      .offset(offset)
      .order(order)
      .keys(this.keys)(this.props.data)
  }

  update() {
    // Show the areas
    let _this = this;
    let t = d3.transition()
      .duration(750)
      .ease(d3.easeCubic)

    // Add X axis
    d3.select('.xaxis')
      .call(d3.axisBottom(this.xScale()).tickSize(15))
      .call(g => g.select(".domain").remove())
      .call(g => g.selectAll(".tick text").attr("y", 22))

    // Add Y axis
    d3.select('.yaxis')
      .call(d3.axisLeft(this.yScale()))
      .call(g => g.select(".domain").remove())
      .call(g => g.selectAll(".tick text").attr("x", 0).style("text-anchor", "start"))
      .call(g => g.selectAll(".tick line").remove())

    d3.select('.stream-data')
      .selectAll('path')
      .data(this.stackedData())
      .style("fill", function(d) { return _this.color()(d.key); })
      .transition(t)
      .attr("d", d3.area()
        .curve(d3.curveBasis)
        .x(function(d, i) { return _this.xScale()(d.data.year); })
        .y0(function(d) { return _this.yScale()(d[0]); })
        .y1(function(d) { return _this.yScale()(d[1]); })
      )
  }

  _setRef(componentNode) {
    this._rootNode = componentNode;
  }

  render() {
    return (
      <div id="stream-graph-container" ref={this._setRef.bind(this)}></div>
    )
  }
}
