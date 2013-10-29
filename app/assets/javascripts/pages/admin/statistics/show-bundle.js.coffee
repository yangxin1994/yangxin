$ ->

  get_color = (d) ->
    users = gon.analyze_result.registered_users
    count = if users["#{d.id}"] then users["#{d.id}"].count.toNumber() else -1
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
    $this = $(selection)
    d3.select(selection)
      .attr("data-style", $this.attr("style"))
      .attr("style", "fill: #{color}")

  recolor = (selection) ->
    $this = $(selection)
    d3.select(selection)
      .attr("style", $this.data("style"))

  # Create Map

  map_chart = ->
    # svg = d3.select('#canvas').append('svg')
    # svg.append('path')
    #   .attr('d', '123.8302214986772 43.42412446912962')
    #   .style('fill', 'none')
    #   .style('stroke', 'purple')
    #   .style('stroke-width', 2)

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
        .attr("style", (d)-> get_color(d))
        .on('mouseover', -> highlight(this, "#f2f2f2"))
        .on("mouseout", -> recolor(this))


      places.selectAll("path")
        .data(collection.features)
        .enter()
        .append("text")
        .attr("class", "place-label")
        .attr("dy", ".35em")
        .attr("transform", (d)-> "translate(#{path.centroid(d)})")
        .text((d)-> d.properties.name)

  pie_chart = ->

    width = 700
    height = 500
    radius = Math.min(width, height) / 2

    color = d3.scale.ordinal()
      .range(["#98abc5", "#8a89a6", "#7b6888", "#6b486b", "#a05d56", "#d0743c", "#ff8c00"])

    arc = d3.svg.arc()
      .outerRadius(radius - 10)
      .innerRadius(0)

    pie = d3.layout.pie()
      .sort(null)
      .value (d) -> 
        d.population

    svg = d3.select("#canvas").insert("svg", "h2")
      .attr("width", width)
      .attr("height", height)
      .append("g")
      .attr("transform", "translate(#{width / 2},#{height / 2})")

    d3.csv "/assets/pages/admin/statistics/data.csv", (error, data) ->
      for d in data
        d.population = +d.population
        
      console.log data
    data = []
    g = svg.selectAll(".arc")
      .data(pie(data))
      .enter()
      .append("g")
      .attr("class", "arc")

    g.append("path")
      .attr("d", arc)
      .style "fill", (d) -> 
        color(d.data.age)

    g.append("text")
      .attr "transform", (d) -> 
        "translate(#{arc.centroid(d)})"
      .attr("dy", ".35em")
      .style("text-anchor", "middle")
      .text (d) -> 
        d.data.age

  pie_chart()



