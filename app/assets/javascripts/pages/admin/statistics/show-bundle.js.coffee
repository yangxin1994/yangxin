$ ->
  do ->
    # svg = d3.select('#canvas').append('svg')
    # svg.append('path')
    #   .attr('d', '123.8302214986772 43.42412446912962')
    #   .style('fill', 'none')
    #   .style('stroke', 'purple')
    #   .style('stroke-width', 2)

    width = 900
    height = 648
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
      console.log collection
      provinces.selectAll("path")
        .data(collection.features)
        .enter()
        .append("path")
        .attr("d", path)
        .attr("class", (d)-> "province p_#{d.id}" )
        .attr("data-name", (d)-> d.properties.name )

      places.selectAll("path")
        .data(collection.features)
        .enter()
        .append("text")
        .attr("class", "place-label")
        .attr("dy", ".35em")
        .attr("transform", (d)-> "translate(#{path.centroid(d)})")
        .text((d)-> d.properties.name)

  $(".province").click(-> alert("a"))


