#= require jquery_ujs
#= require utility/string
#= require jquery.serializeobject
#= require jquery-interdependencies
#= require jquery.placeholder
#= require ui/widgets/od_time_selector
#= require highcharts

$ ->

  set_rules_for_panels = () ->
    build_property_form_rules = (selector) ->
      cfg =
        hide: (control) ->
          control.find('input, textarea, select').attr('disabled', true)
          control.hide()
        show: (control) ->
          control.find('input, textarea, select').attr('disabled', false)
          control.show()

      ruleset = $.deps.createRuleset()

      enum_rule = ruleset.createRule '[name="attribute[type]"]', '==', '1'
      enum_rule.include '.enum-panel'
      array_rule = ruleset.createRule '[name="attribute[type]"]', '==', '7'
      array_rule.include '.array-panel'
      array_rule = ruleset.createRule '[name="attribute[type]"]', 'any', ['3', '5']
      array_rule.include '.date-panel'

      num_rule = ruleset.createRule '[name="attribute[type]"]', 'any', ['2', '4']
      num_rule.include '.num-panel'

      $.deps.enable $(selector), ruleset, cfg

    $('.sample-property-list .body').each (index, elem) ->
      build_property_form_rules elem

    build_property_form_rules '#new_property_panel'

  set_rules_for_panels()
  # form rules end

  # delete item
  $('body').on('click', '.del-btn', (e) ->
    e.preventDefault()
    $(this).closest('p').remove()
  )

  # add item for enum
  enum_input_render = (value) ->
    html = $('#enum_input_tmpl').html()
    html.replace(new RegExp("{{value}}", 'g'), value.value)


  $('body').on 'click', '.add-enum-btn', (e) ->
    e.preventDefault()
    e.stopPropagation()
    html = enum_input_render({value: $(this).prev('input').val()})
    $(this).closest('fieldset').find('.enum-list').append(html)
    $(this).prev('input').val('')

  # add item for num segmentation
  num_input_render = (value) ->
    html = $('#num_input_tmpl').html()
    html.replace(new RegExp("{{value}}", 'g'), value.value)

  $('body').on 'click', '.add-num-btn', (e) ->
    e.preventDefault()
    e.stopPropagation()
    html = num_input_render({value: $(this).prev('input').val()})
    $(this).closest('.segment-new').prev('p').append(html)
    $(this).prev('input').val('')

  # begin date seg

  # load od time selector
  rerender_od_time_selectors = (container) ->
    $('.date-content').each () ->
      $this = $(this)
      format = +$this.closest('.date-panel').find('[name="attribute[date_type]"]').val()
      $this.html($.od.odTimeSelector({format: format}))
      if $this.data('val')
        setTimeout(() ->
          $this.children().first().odTimeSelector('val', $this.data('val'))
        ,
        0)

  $('.date-panel [name="attribute[date_type]"]').change () ->
    rerender_od_time_selectors $(this).closest('.date-panel')

  rerender_od_time_selectors($('body'))
  # add item for date segmentation
  date_widget_render = () ->
    $('#date_input_tmpl').html()

  $('body').on 'click', '.add-date-btn', (e) ->
    format = +$(this).closest('.date-panel').find('[name="attribute[date_type]"]').val()
    e.preventDefault()
    $new_widget = $(date_widget_render()).insertBefore($(this).closest('.segment-new'))

    setTimeout(() ->
      $new_widget.find('.date-content')
                 .append($.od.odTimeSelector({format: format}))
    ,
    0)

  $('body').on('click', '.del-date-btn', (e) ->
    e.preventDefault()
    $(this).closest('.date-seg-wrapper').remove()
  )

  $('.sample-property-list form, #new_property_panel form').submit (e) ->

    $this = $(this)
    console.log $this.find('[name="attribute[type]"]').val()
    if +($this.find('[name="attribute[type]"]').val()) in [3, 5]

      $this.find('.od-time-selector').each () ->
        val = $(this).odTimeSelector('val')
        console.log val
        if val != 946656000000
          $this.append("<input type='hidden' name='attribute[analyze_requirement][segmentation][]' value='#{val}' />")

      return true

  # date-panel end

  # bind validate engine
  $('form').validationEngine()

  # draw pie chart
  pre_process_num_range = (elem) ->
    zipWith = (func, arr1, arr2) ->
      min = Math.min arr1.length, arr2.length
      ret = []

      for i in [0...min]
        ret.push func(arr1[i], arr2[i])

      ret

    zip = (arr1, arr2) ->
      basic_zip = (el1, el2) -> [el1, el2]
      zipWith basic_zip, arr1, arr2

    time_format = (ts, precision) ->
      console.log ts
      date = new Date(ts)
      console.log date
      console.log [123, arguments]
      return switch +precision
        when 0 then "#{date.getFullYear()}"
        when 1 then "#{date.getFullYear()}-#{date.getMonth() + 1}"
        when 2 then "#{date.getFullYear()}-#{date.getMonth() + 1}-#{date.getDate()}"

    $elem = $(elem)
    segmentation = $elem.data('segmentation')
    distribution = $elem.data('distribution')
    type         = $elem.data('type')
    data = null
    console.log segmentation, distribution, type
    switch type
      when 'enum' then data = zip(segmentation, distribution)
      when 'num'
        labels = []
        for seg, i in segmentation
          if i == 0
            labels.push "小于 #{seg}"
          else
            labels.push "#{segmentation[i - 1]} -- #{seg}"
          if i == segmentation.length - 1
            labels.push "大于 #{seg}"

        data = zip(labels, distribution)

      when 'date'
        labels = []
        date_type = $elem.data('date-type')
        dates = (time_format(segmentation[i], date_type) for i of segmentation)
        console.log dates
        for seg, i in dates
          if i == 0
            labels.push "#{seg} 之前"
          else
            labels.push "#{dates[i - 1]} -- #{seg}"
          if i == segmentation.length - 1
            labels.push "#{seg} 之后"

        data = zip(labels, distribution)

    data

  draw_chart = (container, data) ->
    pie_chart = new Highcharts.Chart
      chart:
        type: 'pie'
        renderTo: container
      title:
        text: null
      tooltip:
        pointFormat: '{series.name}: <b>{point.y}</b>'
      plotOptions:
        pie:
          allowPointSelect: true
          cursor: 'pointer'
          dataLabels:
            enabled: true
            color: '#000000'
            connectorColor: '#000000'
            format: '<b>{point.name}</b>: {point.y} %'
      series: [{
        type: 'pie',
        name: 'Browser share'
        data: data
      }]

  $('.pie_chart_container').each (index, elem) ->
    data = pre_process_num_range(elem)
    draw_chart(elem, data)

