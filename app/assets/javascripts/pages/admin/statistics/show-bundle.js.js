// Generated by CoffeeScript 1.6.3
$(function() {
  var bar_chart, get_color, hidden_tips, highlight, map_chart, pie_chart, recolor, show_tips;
  get_color = function(d, samples) {
    var color, count;
    count = samples["" + d.id] ? samples["" + d.id].count.toNumber() : -1;
    if (count <= 0) {
      color = "#ccc";
    } else if (count < 10) {
      color = "#56429b";
    } else if (count < 100) {
      color = "#2f7fb8";
    } else if (count < 300) {
      color = "#61c09f";
    } else if (count < 500) {
      color = "#a7dd9e";
    } else if (count < 800) {
      color = "#e4f791";
    } else if (count < 1000) {
      color = "#f5fca4";
    } else if (count < 1500) {
      color = "#fddf84";
    } else if (count < 2000) {
      color = "#fba959";
    } else if (count < 5000) {
      color = "#f0623c";
    } else if (count < 1000) {
      color = "#cf3047";
    } else if (count >= 10000) {
      color = "#95003b";
    } else {
      color = "#ccc";
    }
    return "fill: " + color;
  };
  highlight = function(selection, color) {
    if (color == null) {
      color = '#fff';
    }
    return d3.select(selection).attr("data-fill", function() {
      return d3.select(this).style("fill");
    }).transition().duration(250).style("fill", color);
  };
  recolor = function(selection) {
    return d3.select(selection).transition().duration(250).style("fill", function() {
      return d3.select(this).attr("data-fill");
    });
  };
  show_tips = function(selection, d, samples) {
    var count, xPositon, yPositon;
    count = samples["" + d.id] ? samples["" + d.id].count.toNumber() : 0;
    xPositon = d3.mouse(selection)[0] + 400;
    yPositon = d3.mouse(selection)[1] + 100;
    d3.select("#tooltip").style("left", "" + xPositon + "px").style("top", "" + yPositon + "px").select("#area_value").text("" + d.properties.name + ": " + count);
    return d3.select("#tooltip").classed("hidden", false);
  };
  hidden_tips = function() {
    return d3.select("#tooltip").classed("hidden", true);
  };
  map_chart = function(samples) {
    var height, path, places, projection, provinces, svg, width;
    samples = gon.analyze_result["" + samples];
    width = 800;
    height = 548;
    projection = d3.geo.conicConformal().rotate([240, 0]).center([-10, 38]).parallels([29.5, 45.5]).scale(800).translate([width / 2, height / 2]).precision(.1);
    path = d3.geo.path().projection(projection);
    svg = d3.select("#canvas").insert("svg", "h2").attr("width", width).attr("height", height);
    provinces = svg.append("g").attr("id", "provinces");
    places = svg.append("g").attr("id", "places");
    return d3.json("/assets/pages/admin/statistics/cn-provinces.json", function(collection) {
      provinces.selectAll("path").data(collection.features).enter().append("path").attr("d", path).attr("class", function(d) {
        return "province p_" + d.id;
      }).attr("data-name", function(d) {
        return d.properties.name;
      }).attr("style", function(d) {
        return get_color(d, samples);
      }).on('mouseover', function(d) {
        highlight(this, "#f2f2f2");
        return show_tips(this, d, samples);
      }).on("mouseout", function() {
        recolor(this);
        return hidden_tips();
      });
      provinces.selectAll("d").append("title").text(function(d) {
        return d.properties.name;
      });
      return places.selectAll("path").data(collection.features).enter().append("text").attr("class", "place-label").attr("dy", ".35em").attr("transform", function(d) {
        return "translate(" + (path.centroid(d)) + ")";
      }).text(function(d) {
        return d.properties.name;
      });
    });
  };
  pie_chart = function(samples) {
    var arc, color, data, g, height, index, item, pie, radius, svg, width, _i, _len, _ref;
    samples = gon.analyze_result["" + samples];
    width = 700;
    height = 500;
    radius = Math.min(width, height) / 2;
    data = [];
    _ref = gon.enum_array;
    for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
      item = _ref[index];
      data.push({
        _key: item,
        _value: samples[index]
      });
    }
    color = d3.scale.ordinal().range(["#f0623c", "#fba959", "#fddf84", "#f5fca4", "#e4f791", "a7dd9e", "61c09f", "2f7fb8"]);
    arc = d3.svg.arc().outerRadius(radius - 10).innerRadius(0);
    pie = d3.layout.pie().sort(null).value(function(d) {
      return d._value;
    });
    svg = d3.select("#canvas").insert("svg", "h2").attr("width", width).attr("height", height).append("g").attr("transform", "translate(" + (width / 2) + "," + (height / 2) + ")");
    g = svg.selectAll(".arc").data(pie(data)).enter().append("g").attr("class", "arc");
    g.append("path").attr("d", arc).style("fill", function(d) {
      return color(d.data._value);
    });
    g.selectAll("path").on("mouseover", function(d) {
      return highlight(this, "#f2f2f2");
    }).on("mouseout", function() {
      return recolor(this);
    });
    return g.append("text").attr("transform", function(d) {
      return "translate(" + (arc.centroid(d)) + ")";
    }).attr("dy", ".35em").style("text-anchor", "middle").text(function(d) {
      return "" + d.data._key + "(" + d.data._value + ")";
    });
  };
  bar_chart = function(samples) {
    var height, k, sample, svg, v, width, _results;
    width = 100;
    height = 800;
    _results = gon.analyze_result["" + samples];
    sample = {};
    samples = (function() {
      var _results1;
      _results1 = [];
      for (k in _results) {
        v = _results[k];
        _results1.push(v.count);
      }
      return _results1;
    })();
    console.log(samples);
    svg = d3.select("#canvas_side").append("svg").attr("width", width).attr("height", height);
    return svg.selectAll("rect").data(samples).enter().append("rect").attr("y", function(d, i) {
      return i * 21;
    }).attr("x", 0).style("fill", "#fba959").style("stroke", "#ffffff").attr("width", 0).transition().duration(1500).attr("width", function(d, i) {
      return d / 40 + 1;
    }).attr("height", 20);
  };
  switch (gon.chart_type) {
    case 1:
    case 2:
    case 3:
    case 4:
    case 5:
    case 7:
      return pie_chart(querilayer.queries.samples || "registered_users");
    case 6:
      map_chart(querilayer.queries.samples || "registered_users");
      return bar_chart(querilayer.queries.samples || "registered_users");
  }
});
