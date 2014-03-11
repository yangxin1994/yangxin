#= require "d3.v3"

$ ->

  highlight = (selection, color = '#fff') ->
    d3.select(selection)
      .attr("data-fill", -> d3.select(selection).style("fill") )
      .style("fill", color)

  recolor = (selection) ->
    d3.select(selection)
      .style("fill", -> d3.select(selection).attr("data-fill"))

  show_tips = (selection, d, samples)->
    count = if samples["#{d.id}"] then samples["#{d.id}"].count.toNumber() else 0
    xPositon = d3.mouse(selection)[0] + (window.screen.availWidth - 960) / 2
    yPositon = d3.mouse(selection)[1] + 30



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
    color = d3.scale.ordinal()
      .range(["#ccc", "#56429b", "#2f7fb8", "#61c09f", "#a7dd9e", "#e4f791", "#f5fca4", "#fddf84", "#fba959", "#f0623c", "#cf3047", "#95003b"])

    projection = d3.geo.conicConformal()
      .rotate([240, 0])
      .center([-10, 38])
      .parallels([29.5, 45.5])
      .scale(800)
      .translate([width / 2, height / 2])
      .precision(.1);

    # projection = d3.geo.miller()
    #   .scale(800)

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
        .style("fill", (d)-> 
          count = if samples["#{d.id}"] then samples["#{d.id}"].count.toNumber() else -1
          color(count))
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
    samples = gon.analyze_result["#{samples}"] || []

    width = 700
    height = 500
    radius = Math.min(width, height) / 2
    data = []
    switch gon.chart_type
      when 2, 4
        for item, index in gon.analyze_requirement.segmentation
          if index == 0
            data.push 
              _key: "小于 #{item}"
              _value: samples[index] || 0
            item = "#{item} ~ #{gon.analyze_requirement.segmentation[index + 1]}"
          else if index == gon.analyze_requirement.segmentation.length - 1
            item = "大于 #{item}"
          else
            item = "#{item} ~ #{gon.analyze_requirement.segmentation[index + 1]}"
          data.push 
            _key: item
            _value: samples[index] || 0 
      when 3, 5
        for item, index in gon.analyze_requirement.segmentation
          item = item * 1000
          time_min = Date.create(item)
          time_max = Date.create(gon.analyze_requirement.segmentation[index + 1] * 1000)

          switch gon.date_type
            when 0
              str_min = time_min.format("{yyyy}年")
              str_max = time_max.format("{yyyy}年")
            when 1
              str_min = time_min.format("{yyyy}年{Month}月")
              str_max = time_max.format("{yyyy}年{Month}月")
            when 2
              year_flag = false
              month_flag = false
              str_min = time_min.format('short', 'ja')
              str_max = time_max.format('short', 'ja')
              if time_min.getYear() == time_max.getYear()
                str_max = time_max.format("{Month}月{d}日")
                year_flag = true
              if year_flag && time_min.getMonth() == time_max.getMonth()
                str_max = time_max.format("{d}日")

          if index == 0
            data.push 
              _key: "早于 #{str_min}"
              _value: samples[index] || 0
            item = "#{str_min} ~ #{str_max}"
          else if index == gon.analyze_requirement.segmentation.length - 1
            item = "晚于 #{str_min}"
          else
            item = "#{str_min} ~ #{str_max}"
          data.push 
            _key: item
            _value: samples[index] || 0
      when 1, 7
        for item, index in gon.enum_array
          data.push 
            _key: item
            _value: samples[index] || 0
    console.log data
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
    g.append("title")
      .text (d) -> 
        "#{d.data._key}(#{d.data._value})"

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
    collection = {}

    color = d3.scale.ordinal()
      .range(["#ccc", "#56429b", "#2f7fb8", "#61c09f", "#a7dd9e", "#e4f791", "#f5fca4", "#fddf84", "#fba959", "#f0623c", "#cf3047", "#95003b"])

    _results = gon.analyze_result["#{samples}"]
    samples_with_name = {}
    samples = for k, v of _results
      # sample["#{k}"] = 
      v.count

    svg = d3.select("#canvas_side")
      .append("svg")
      .attr("width", width)
      .attr("height", height)

    d3.json "/assets/pages/admin/statistics/cn-provinces.json", (cols) ->
      item = {}
      for col in cols.features
        for k, v of _results
          if col.id == k
            samples_with_name["#{k}"] = 
              name: col.properties.name
              count: v.count
        

    svg.selectAll("rect")
      .data(samples)
      .enter()
      .append("rect")
      .attr("y", (d, i)-> i * 24)
      .attr("x", 0)
      .style("fill", (d)-> color(d))
      .style("stroke", "#ffffff")
      .attr("width", 0)
      .transition()
      .duration(1500)
      .attr("width", (d, i) -> d / 40 + 1)
      .attr("height", 20)

    svg.selectAll("text")
      .data(samples)
      .enter()
      .append("text")
      .attr("y", (d, i)-> i * 24 + 14 )
      .attr("x", (d) -> d / 40 + 1)
      .text((d)-> d )

  switch gon.chart_type
    when 1, 2, 3, 4, 5, 7
      pie_chart(querilayer.queries.samples || "registered_users")
    when 6
      map_chart(querilayer.queries.samples || "registered_users")
      # bar_chart(querilayer.queries.samples || "registered_users")
  



