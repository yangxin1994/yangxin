#= require highcharts

class DateRangeGenerator
  day = 1000 * 86400
  week = day * 7
  year = day * 365

  date_format = (date) ->
    date = new Date(+date)
    "#{date.getFullYear()}-#{date.getMonth() + 1}-#{date.getDate()}"

  generate_range = (time, num) ->
    (date_format(new Date() - time * period) for period in [0...num]).reverse()

  day_range: (num) ->
    generate_range(day, num)

  week_range: (num) ->
    generate_range(week, num)

  year_range: (num) ->
    generate_range(year, num)

date_range_generator = new DateRangeGenerator

class SampleStatChartWidget
  constructor: (wrap_container, @chart_container, @url, @chart_title, data_parse) ->
    @$wrap_container = $(wrap_container)

    $period = @$wrap_container.find('select[name=period]')
    $time_length = @$wrap_container.find('select[name=time_length]')
    $submit_btn = @$wrap_container.find('button').first()
    $chart_type = @$wrap_container.find('select[name=type]')

    $submit_btn.click((e) =>
      $this = $(e.currentTarget)
      $this.attr 'disabled', true
      time_length = $time_length.val()
      chart_type = $chart_type.val()

      if chart_type == 'unit'
        time_length += 1

      $.get @url, {period: $period.val(), time_length: $time_length.val()}, (data) =>
        data = data_parse(data) if data_parse
        values = []
        if chart_type == 'unit'
          `
          for (var i = 1; i < data.length; i++)
            values.push(data[i] - data[i - 1])
          `
        else
          values = data

        _render_chart($period.val(), $time_length.val(), values, @chart_container, @chart_title)
        $submit_btn.attr 'disabled', false
    )

    # trigger it
    $period.val('day')
    $time_length.val(15)
    $chart_type.val('unit')
    $submit_btn.click()

  # prepare data for hightcharts render
  _render_chart = (period, time_length, data, chart_container, chart_title) ->
    labels = null
    switch period
      when 'year' then labels = date_range_generator.year_range(time_length)
      when 'week' then labels = date_range_generator.week_range(time_length)
      when 'day'  then labels = date_range_generator.day_range(time_length)

    _generate_sample_stats_charts {
      chart_container: chart_container
      chart_title: chart_title,
      chart_data: data
      chart_labels: labels
    }

  # render highcharts
  _generate_sample_stats_charts = (opts) ->
    {chart_container, chart_title, chart_data, chart_labels} = opts

    sample_stats_charts = new Highcharts.Chart
      title:
        text: null
      chart:
        type: 'column'
        renderTo: chart_container
      xAxis:
        categories: chart_labels
        labels:
          rotation: -45
          align: 'right'
          style:
            fontSize: '13px'
            fontFamily: 'Verdana, sans-serif'
      yAxis:
        min: 0
        title:
          text: '样本个数'
      series: [
        {
          name: chart_title,
          data: chart_data
        }
      ]


$ ->
  sample_chart = new SampleStatChartWidget(
    '#sample_stats_panel',
    'sample_stats_charts',
    '/admin/samples/get_sample_count',
    '样本个数',
    (data) ->
      data = data.value
      data.new_sample_number
  )
  active_sample_chart = new SampleStatChartWidget(
    '#active_sample_stats_panel',
    'active_sample_stats_charts',
    '/admin/samples/get_active_sample_count', 
    '活跃样本个数',
    (data) ->
      data = data.value)
