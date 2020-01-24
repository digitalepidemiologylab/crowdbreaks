import * as d3 from 'd3';
import React from 'react';

export class D3StreamGraph extends React.Component {
  constructor(props) {
    super(props);
    this.margin = {top: 40, right: 0, bottom: 35, left: 0};
    this.width = this.props.width - this.margin.left - this.margin.right;
    this.height = this.props.height - this.margin.top - this.margin.bottom;
    this.timeFormat = d3.timeFormat("%H:%M");
    this.toolboxTimeFormat = d3.timeFormat("%H:%M %b %d, %Y");
    this.legendPos = this.props.legendPos;
    // scale legend pos down a bit on mobile (legend items will appear closer together)
    if (this.props.device == 'mobile') {
      this.legendPos = this.props.legendPos.map((i) => i * 1)
    }
  }

  componentDidMount() {
    this.create()
  }

  componentDidUpdate() {
    this.update();
  }

  create() {
    // append the svg object to the body of the page
    let svg = d3.select(this._rootNode).append('svg')
    let fig = svg
      .attr("width", this.props.width)
      .attr("height", this.props.height)
      .append("g")
      .attr("transform",
        "translate(" + this.margin.left + "," + this.margin.top + ")")
      .attr('class', 'figure');

    // plotting area
    fig.append('g')
      .attr('class', 'stream-data')
      .selectAll('paths')
      .data(this.stackedData())
      .enter()
      .append("path")

    // Add X axis
    fig.append("g")
      .attr('class', 'stream-graph-axis xaxis')
      .attr("transform", "translate(0," + this.height + ")")

    // Add Y axis
    fig.append("g")
      .attr('class', 'stream-graph-axis yaxis')

    // legend
    let legend = svg.append('g').attr('class', 'legend')
    legend.selectAll('legend-dots')
      .data(this.props.keys)
      .enter()
      .append('circle')
      .attr('cx', (d, i) => {return this.margin.left + 10 + this.legendPos[i]})
      .attr('cy', 6)
      .attr('r', 6)
      .style('fill', (d) => {return this.color(d)})
    legend.selectAll('legend-text')
      .data(this.props.keys)
      .enter()
      .append('text')
      .attr('x', (d, i) => {return this.margin.left + 20 + this.legendPos[i]})
      .attr('y', 7)
      .text((d) => {return d})
      .attr("text-anchor", "left")
      .style("dominant-baseline", "middle")

    // tooltip
    this.createTooltip();

    this.update();
  }

  createTooltip() {
    let tooltipContainer = d3.select('svg').append('g').attr('class', 'tooltip-container')

    // html tooltip
    let tooltip = d3.select('#d3-stream-graph-container')
      .append("div")
      .attr("class", "stream-graph-tooltip")
      .style("display", 'none')
      .style("height", '145px')
    let tooltipSvg = tooltip.append('svg').attr('width', 190).attr('height', 180)

    // draw svg within tooltip div
    tooltipSvg
      .append('g')
      .append('text')
      .attr('class', 'sg-tooltip-title')
      .attr('x', 0)
      .attr('y', 12)
      .attr('height', 12)
      .attr('width', 100)
      .text('Title')

    let tooltipInfo = tooltipSvg
      .append('g')
      .attr('class', 'sg-tooltip-info')
      .selectAll('labels')
      .data(this.props.keys.slice().reverse())
      .enter()

    // Symbols in tooltip
    tooltipInfo
      .append('circle')
      .attr('cx', 6)
      .attr('cy', (d, i) => (i+1)*18 + 8)
      .attr('r', 6)
      .style('fill', (d) => this.color(d))

    // Text in tooltip
    tooltipInfo
      .append('text')
      .text((d) => d)
      .attr('y', (d, i) => {return (i+1)*18 + 13})
      .attr('x', 20)

    // Vertical line indicator
    let verticalLine = d3.select('.figure')
      .append("path")
      .attr("class", "tooltip-vertical-line")
      .style("stroke", "white")
      .style("stroke-width", "1px")
      .style("opacity", 0);

    // activate tooltip once mouse moves into this area
    let tooltipMouseOver = tooltipContainer
      .append("rect")
      .attr("id", "tooltip-mousover")
      .attr("x", this.margin.left)
      .attr("y", this.margin.top)
      .attr("width", this.width)
      .attr("height", this.height)
      .style("opacity", 0)

    // mouse events
    const _this = this;
    tooltipMouseOver
      .on("mouseover", function(){
        tooltip.style('display', 'block')
        verticalLine.style("opacity", 1);
      })
      .on("touchmove mousemove", function() {
        // Get mouse position
        const mouse = d3.mouse(this);
        // since we will modify the data, make sure to work on a copy of the bisected data (hence the spread operator)
        let focusData = {..._this.bisect(mouse[0]-8)};
        // Update position
        const xpos = _this.xScale()(focusData.date);
        verticalLine
          .attr("d", () => {
            var d = "M" + (xpos) + "," + (_this.height);
            d += " " + (xpos) + "," + 0;
            return d;
          });
        tooltip
          .style("left", (xpos) + "px")
          .style("top", (mouse[1]+30) + "px")
        // Update tooltip
        d3.select('.sg-tooltip-title')
          .text(_this.toolboxTimeFormat(focusData.date))
        tooltipInfo
          .selectAll('text')
          .text((key) => focusData[key] + ' matches for ' + key)

      })
      .on("mouseout", function(){
        tooltip.style('display', 'none')
        verticalLine.style("opacity", 0);
      });
  }


  bisect(mx) {
    const bisect = d3.bisector(d => d.date).left;
    const date = this.xScale().invert(mx);
    const index = bisect(this.props.data, date, 1);
    const a = this.props.data[index - 1];
    if (index >= this.props.data.length) {
      return a
    }
    const b = this.props.data[index];
    return date - a.date > b.date - date ? b : a;
  }

  xScale() {
    return d3.scaleTime().domain(d3.extent(this.props.data, function(d) { return d.date; })).range([0, this.width])
  }

  yScale() {
    let extent;
    switch (this.props.vizOption) {
      case 'normal':
        extent = [0, 1];
        break;
      case 'wiggle':
        extent = d3.extent(this.props.data, (d) => {
          let totalSum = 0;
          this.props.keys.forEach((key) => {
            totalSum += d[key]
          })
          return totalSum
        });
        const diff = (extent[1] - extent[0])/2 * 1.6;
        extent = [-diff, diff];
        break;
      case 'zero':
        const max = d3.max(this.props.data, (d) => {
          let totalSum = 0;
          this.props.keys.forEach((key) => {
            totalSum += d[key]
          })
          return totalSum
        });
        extent = [0, max];
        break;
    }
    return d3.scaleLinear().domain(extent).range([ this.height, 0 ]);
  }

  color(d) {
    return d3.scaleOrdinal().domain(this.props.keys).range(this.props.colors)(d)
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
      .keys(this.props.keys)(this.props.data)
  }

  update() {
    // Show the areas
    let _this = this;

    let t = d3.transition().duration(0)
    if (this.props.useTransition) {
      t = d3.transition() .duration(500).ease(d3.easeCubic)
    }
    // By default let d3 figure out how many ticks, but on tablet/mobile reduce ticks
    let numTicks = null;
    if (this.props.device == 'mobile' || this.props.device == 'tablet') {
      numTicks = 5;
    }

    // Add X axis

    let xaxis = d3.axisBottom(this.xScale())
        .tickSize(15)
        .tickFormat(this.multiFormat)
        .ticks(numTicks)

    d3.select('.xaxis')
      .call(xaxis)
      .call(g => g.select(".domain").remove())
      .call(g => g.selectAll(".tick text").attr("y", 22))

    // Remove xticks which are too close to border
    let firstTick = d3.select('.xaxis .tick:first-child')
    let firstTickTransform = firstTick.attr('transform');
    let firstTickX = firstTickTransform.substring(firstTickTransform.indexOf("(")+1, firstTickTransform.indexOf(")")).split(",")[0];
    if (firstTickX < 20) {
      firstTick.remove()
    }
    let lastTick = d3.select('.xaxis .tick:last-child')
    let lastTickTransform = lastTick.attr('transform');
    let lastTickX = lastTickTransform.substring(lastTickTransform.indexOf("(")+1, lastTickTransform.indexOf(")")).split(",")[0];
    if (lastTickX > this.width - 10) {
      lastTick.remove()
    }

    // Add Y axis
    d3.select('.yaxis')
      .call(d3.axisLeft(this.yScale()))
      .call(g => g.select(".domain").remove())
      .call(g => g.selectAll(".tick text").attr("x", 0).style("text-anchor", "start"))
      .call(g => g.selectAll(".tick line").remove())

    d3.select('.stream-data')
      .selectAll('path')
      .data(this.stackedData())
      .style("fill", function(d) { return _this.color(d.key); })
      .transition(t)
      .attr("d", d3.area()
        .curve(d3.curveBasis)
        .x(function(d, i) { return _this.xScale()(d.data.date); })
        .y0(function(d) { return _this.yScale()(d[0]); })
        .y1(function(d) { return _this.yScale()(d[1]); })
      )
  }

  multiFormat(date) {
    var formatMillisecond = d3.timeFormat(".%L"),
      formatSecond = d3.timeFormat(":%S"),
      formatMinute = d3.timeFormat("%I:%M"),
      formatHour = d3.timeFormat("%H:%M"),
      formatDay = d3.timeFormat("%a %d"),
      formatWeek = d3.timeFormat("%b %d"),
      formatMonth = d3.timeFormat("%b"),
      formatYear = d3.timeFormat("%Y");

    return (d3.timeSecond(date) < date ? formatMillisecond
      : d3.timeMinute(date) < date ? formatSecond
      : d3.timeHour(date) < date ? formatMinute
      : d3.timeDay(date) < date ? formatHour
      : d3.timeMonth(date) < date ? (d3.timeWeek(date) < date ? formatDay : formatWeek)
      : d3.timeYear(date) < date ? formatMonth
      : formatYear)(date);
  }

  _setRef(componentNode) {
    this._rootNode = componentNode;
  }

  render() {
    return (
      <div>
        <div id="d3-stream-graph-container" ref={this._setRef.bind(this)}></div>
      </div>
    )
  }
}
