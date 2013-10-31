$ ->

  get_color = (d, samples) ->
    count = if samples["#{d.id}"] then samples["#{d.id}"].count.toNumber() else -1
    if count <= 0
      color = "#ccc"
    else if count < 10
      color = "#56429b"
    else if count < 100
      color = "#2f7fb8"
    else if count < 300
      color = "#61c09f"
    else if count < 500
      color = "#a7dd9e"
    else if count < 800
      color = "#e4f791"
    else if count < 1000
      color = "#f5fca4"
    else if count < 1500
      color = "#fddf84"
    else if count < 2000
      color = "#fba959"
    else if count < 5000
      color = "#f0623c"
    else if count < 1000
      color = "#cf3047"
    else if count >= 10000
      color = "#95003b"
    else
      color = "#ccc"
    "fill: #{color}"

  highlight = (selection, color = '#fff') ->
    d3.select(selection)
      .attr("data-fill", -> d3.select(this).style("fill") )
      .transition()
      .duration(250)
      .style("fill", color)

  recolor = (selection) ->
    d3.select(selection)
      .transition()
      .duration(250)    
      .style("fill", -> d3.select(this).attr("data-fill"))

  show_tips = (selection, d, samples)->
    count = if samples["#{d.id}"] then samples["#{d.id}"].count.toNumber() else 0
    xPositon = d3.mouse(selection)[0] +  400
    yPositon = d3.mouse(selection)[1] + 100

    d3.select("#tooltip")
      .style("left", "#{xPositon}px")
      .style("top", "#{yPositon}px")
      .select("#area_value")
      .text("#{d.properties.name}: #{count}")

    d3.select("#tooltip").classed("hidden", false)

  hidden_tips = ->
    d3.select("#tooltip").classed("hidden", true)

  # Create Map

  map_chart = (samples)->
    # svg = d3.select('#canvas').append('svg')
    # svg.append('path')
    #   .attr('d', '123.8302214986772 43.42412446912962')
    #   .style('fill', 'none')
    #   .style('stroke', 'purple')
    #   .style('stroke-width', 2)
    samples = gon.analyze_result["#{samples}"]

    width = 800
    height = 548
      # 

    projection = d3.geo.conicConformal()
      .rotate([240, 0])
      .center([-10, 38])
      .parallels([29.5, 45.5])
      .scale(800)
      .translate([width / 2, height / 2])
      .precision(.1);
    
    path = d3.geo.path()
      .projection(projection)


    svg = d3.select("#canvas").insert("svg", "h2")
      .attr("width", width)
      .attr("height", height)

    provinces = svg.append("g")
      .attr("id", "provinces")

    places = svg.append("g")
      .attr("id", "places")

    d3.json "/assets/pages/admin/statistics/cn-provinces.json", (collection) ->
      provinces.selectAll("path")
        .data(collection.features)
        .enter()
        .append("path")
        .attr("d", path)
        .attr("class", (d)-> "province p_#{d.id}" )
        .attr("data-name", (d)-> d.properties.name )
        .attr("style", (d)-> get_color(d, samples))
        .on('mouseover', (d)-> highlight(this, "#f2f2f2"); show_tips(this, d, samples))
        .on("mouseout", -> recolor(this); hidden_tips())
      
      provinces.selectAll("d")
        .append("title")
        .text((d)-> d.properties.name )

      places.selectAll("path")
        .data(collection.features)
        .enter()
        .append("text")
        .attr("class", "place-label")
        .attr("dy", ".35em")
        .attr("transform", (d)-> "translate(#{path.centroid(d)})")
        .text((d)-> d.properties.name)

  pie_chart = (samples)->
    samples = gon.analyze_result["#{samples}"]

    width = 700
    height = 500
    radius = Math.min(width, height) / 2
    data = []


    for item, index in gon.enum_array
      data.push 
        _key: item
        _value: samples[index]

    color = d3.scale.ordinal()
      .range(["#f0623c", "#fba959", "#fddf84", "#f5fca4", "#e4f791", "a7dd9e", "61c09f", "2f7fb8"])
      # .range(["#98abc5", "#8a89a6", "#7b6888", "#6b486b", "#a05d56", "#d0743c", "#ff8c00"])

    arc = d3.svg.arc()
      .outerRadius(radius - 10)
      .innerRadius(0)

    pie = d3.layout.pie()
      .sort(null)
      .value (d) -> 
        d._value

    svg = d3.select("#canvas").insert("svg", "h2")
      .attr("width", width)
      .attr("height", height)
      .append("g")
      .attr("transform", "translate(#{width / 2},#{height / 2})")

    g = svg.selectAll(".arc")
      .data(pie(data))
      .enter()
      .append("g")
      .attr("class", "arc")

    g.append("path")
      .attr("d", arc)
      .style "fill", (d) -> 
        color(d.data._value)

    g.selectAll("path")
      .on("mouseover", (d)-> highlight(this, "#f2f2f2"))
      .on("mouseout", -> recolor(this))

    # g.data(pie(data))
    #   .transition()

    g.append("text")
      .attr "transform", (d) -> 
        "translate(#{arc.centroid(d)})"
      .attr("dy", ".35em")
      .style("text-anchor", "middle")
      .text (d) -> 
        "#{d.data._key}(#{d.data._value})"

  bar_chart = (samples)->

    width = 100
    height = 800

    _results = gon.analyze_result["#{samples}"]
    sample = {}

    samples = for k, v of _results
      # sample["#{k}"] = 
      v.count

    console.log samples

    svg = d3.select("#canvas_side")
      .append("svg")
      .attr("width", width)
      .attr("height", height)

    svg.selectAll("rect")
      .data(samples)
      .enter()
      .append("rect")
      .attr("y", (d, i)->i * 21 )
      .attr("x", 0)
      .style("fill", "#fba959")
      .style("stroke", "#ffffff")
      .attr("width", 0)
      .transition()
      .duration(1500)
      .attr("width", (d, i) -> d / 40 + 1)
      .attr("height", 20)





  switch gon.chart_type
    when 1, 2, 3, 4, 5, 7
      pie_chart(querilayer.queries.samples || "registered_users")
    when 6
      map_chart(querilayer.queries.samples || "registered_users")
      bar_chart(querilayer.queries.samples || "registered_users")
  



