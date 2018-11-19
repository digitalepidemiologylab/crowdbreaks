// React
import React from 'react'

import Vega from 'react-vega';
import { Input, Col, Row, FormText } from 'reactstrap';

export class SentimentMap extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      data: {},
      start_date: this.props.start_date,
      end_date: this.props.end_date,
    };
  }

  componentWillMount() {
    this.setData();
  }

  setData() {
    const data = {
      "viz": {
        "es_index_name": this.props.es_index_name,
        "start_date": this.state.start_date,
        "end_date": this.state.end_date
      }
    };
    const label_dict = {'-1': 'anti-vaccine', 0: 'neutral', 1: 'pro-vaccine'}
    $.ajax({
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      type: "POST",
      crossDomain: true,
      url: this.props.updateVisualizationPath,
      data: JSON.stringify(data),
      dataType: "json",
      contentType: "application/json",
      success: (result) => {
        this.setState({
          data: result.map((d) => new Object({
            "longitude": d._source.place.average_location[0], 
            "latitude": d._source.place.average_location[1],
            "label": label_dict[d._source.meta.sentiment.fasttext_v1.label_val]
          })) 
        });
      }
    });
  }

  refresh() {
    this.setData();
  }

  handleChangeStart(event) {
    this.setState({
      start_date: event.target.value
    })
  }

	handleChangeEnd(event) {
		this.setState({
			end_date: event.target.value
		})
	}

  render() {
    const spec = {
      "padding": 5,
      "width": 1000,
      "height": 800,
      "projections": 
      [
        {
          "name": "projection",
          "size": {"signal": "[width, height]"},
          "fit": {"signal": "data('source_0')"},
          "type": "mercator",
          "clipExtent": [[0, 100], [1000, 600]]
        }
      ],

      "marks": 
      [
        {
          "name": "layer_0_marks",
          "type": "shape",
          "style": ["geoshape"],
          "from": {"data": "source_0"},
          "encode": {
            "update": {
              "fill": {"value": "white"},
              "stroke": {"value": "#bbb"},
              "strokeWidth": {"value": 0.5}
            }
          },
          "transform": [{"type": "geoshape", "projection": "projection"}]
        },
        {
          "name": "layer_1_marks",
          "type": "symbol",
          "style": ["circle"],
          "from": {"data": "source_1"},
          "encode": {
            "update": {
              "opacity": {"value": 0.7},
              "fill": {
                "scale": "color",
                "field": "label"
              },
              "x": {"field": "layer_1_x"},
              "y": {"field": "layer_1_y"},
              "size": {"value": 5},
              "shape": {"value": "circle"}
            }
          }
        }
      ],

      "config": {"axisY": {"minExtent": 30}},

      "data": 
      [
        {
          "name": "source_0",
          "url": "https://vega.github.io/editor/data/world-110m.json",
          "format": {"type": "topojson", "feature": "countries"}
        },
        {
          "name": "source_1",
          "values": this.state.data,
          "transform": [
            {
              "type": "geojson",
              "fields": ["longitude", "latitude"],
              "signal": "layer_1_geojson_0"
            },
            {
              "type": "geopoint",
              "projection": "projection",
              "fields": ["longitude", "latitude"],
              "as": ["layer_1_x", "layer_1_y"]
            }
          ]
        }
      ],

      "scales": [
        {
          "name": "color",
          "type": "ordinal",
          "domain": {
            "data": "source_1",
            "field": "label",
            "sort": true
          },
          "range": ["#db4457", "#1e9CeA", "#5bb12a"]
        }
      ],

      "legends": [
        {
          "orient": "top-left",
          "type": "symbol",
          "fill": "color",
          "title": "Sentiment",
          "encode": {
            "symbols": {
              "update": {"shape": {"value": "circle"}, "opacity": {"value": 0.7}}
            }
          }
        }
      ]
    };

    return (
      <div>
        <Row className="mb-4">
          <Col>
            <Row>
              <Col xs="12" md="6">
                <div className="form-group">
                  <label className="label-form-control">Start</label>
                  <Input type="text" name="start_date" onChange={(ev) => this.handleChangeStart(ev)} value={this.state.start_date}/>
                  <FormText color="muted">Format: YYYY-MM-dd HH:mm:ss</FormText>
                </div>
              </Col>
              <Col xs="12" md="6">
                <div className="form-group">
                  <label className="label-form-control">End</label>
                  <Input type="text" name="end_date" onChange={(ev) => this.handleChangeEnd(ev)} value={this.state.end_date}/>
                  <FormText color="muted">Format: YYYY-MM-dd HH:mm:ss</FormText>
                </div>
              </Col>
            </Row>
            <button className="btn btn-primary" onClick={() => this.refresh()}>Refresh</button>
          </Col>
        </Row>

        <Row>
          <Col>
            <Vega spec={spec}/>
          </Col>
        </Row>
      </div>
    );
  }
}
