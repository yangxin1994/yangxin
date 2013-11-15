#= require handlebars.runtime
# =require jquery-ui-min
#= require utility/string
#= require utility/util
#= require utility/ajax
#= require jquery.placeholder
#= require ui/widgets/od_address_selector
#= require ui/widgets/od_time_selector
#= require jquery-interdependencies
#= require_tree ../templates

$ ->
  to_panel_class = (name) ->
    name.replace(/_/g, '-') + '-panel'

  # rerender the address widget on the select change
  $('body').on 'change', '[name=loc_precision]', () ->
    self = this
    $(this).closest('.panel').find('.address-content').each () ->
      $(this).html $.od.odAddressSelector({
        precision: +$(self).val(),
        has_postcode: false
      })

  tmpl_prefix = 'pages/admin/templates/'

  # this is the mapper between sample attr type and tmpls
  render_mapper = {
    1: 'enum',
    4: 'num_range',
    5: 'date_range',
    6: 'address',
    7: 'enum'
  }

  current_attr = null # current selected attr
  type = null # type of attr
  # on change reload the partial for bind attrs
  $('[name=type]').change () ->
    value = $(this).val()
    # console.log value
    current_attr = attr = $.grep(attrs, (a) ->
      return a._id == value
    )[0]

    console.log attr.enum_array
    type = current_attr.type
    # console.log question.issue.max_choice
    # console.log "type: #{render_mapper[type]}"

    # question_type == 0 means only choice questions have tmpls
    if render_mapper[type] && question['question_type'] == 0
      tmpl = "#{tmpl_prefix}#{render_mapper[type]}"
      $('.panel-wrapper').html(HandlebarsTemplates[tmpl]({
        question: question,
        attr: attr
      }))

      if type == 5 # date-range
        setTimeout(() ->
          $('.date-range-panel .date-selector-content').each () ->
            $.od.odTimeSelector({format: attr.date_type}).appendTo(this)
        ,
        0)
      else if type == 6 # address view
        setTimeout(() ->
          $('.address-panel .address-content').each () ->
            $.od.odAddressSelector({
              precision: 0,
              has_postcode: false
            }).appendTo(this)
        ,
        0)

    else # no extra view
      $('.panel-wrapper').empty()

  # if this question already has binded attr
  if question.sample_attribute_id
    current_attr = attr = $.grep(attrs, (a) ->
      return a._id == question.sample_attribute_id
    )[0]

    type = current_attr.type

    $('[name=type]').val(question.sample_attribute_id).change()

    mapped_type = render_mapper[type]

    # render the panel with val
    if mapped_type && question['question_type'] == 0
      tmpl = "#{tmpl_prefix}#{render_mapper[type]}"
      $('.panel-wrapper').html(HandlebarsTemplates[tmpl]({
        question: question,
        attr: attr
      }))

      relation = question.sample_attribute_relation
      panel_class = to_panel_class mapped_type

      if mapped_type == 'date_range' # date-range

        setTimeout(() ->
          $(".#{panel_class} table tbody tr").each () ->
            $this = $(this)
            item_id = $this.find('[data-id]').data('id')
            $this.find('.first .od-time-selector').odTimeSelector('val', relation[item_id][0])
            $this.find('.second .od-time-selector').odTimeSelector('val', relation[item_id][1])
        ,
        0)
      else if type == 6 # address view
        setTimeout(() ->
          $('[name=loc_precision]').val(addr_precision).change()
        ,
        0)
        setTimeout(() ->
          $(".#{panel_class} table tbody tr").each () ->
            $this = $(this)
            item_id = $this.find('[data-id]').data('id')
            $this.find('.address-slt').odAddressSelector('val', {address: relation[item_id]})
        ,
        50)
      else if render_mapper[type] == 'enum'
        setTimeout(() ->
          $(".#{panel_class} table tbody tr").each () ->
            $this = $(this)
            item_id = $this.find('[data-id]').data('id')
            $this.find('select').val(relation[item_id])
        )
      else if mapped_type == 'num_range'
        setTimeout(() ->
          $(".#{panel_class} table tbody tr").each () ->
            $this = $(this)
            item_id = $this.find('[data-id]').data('id')
            $this.find('.range-input.first').val(relation[item_id][0])
            $this.find('.range-input.second').val(relation[item_id][1])
        )

    else # no extra view
      $('.panel-wrapper').empty()



  generate_relation  = (name) ->
    panel_class = to_panel_class(name)

    relation = {}

    # this is a mapper for processing different views
    mapper = {
      'enum': (panel_class) ->
        $(".#{panel_class} table tbody tr").each () ->
          $this = $(this)
          item_id = $this.find('[data-id]').data('id')
          val = $this.find('select').val()
          relation[item_id] = val if val.length > 0
        relation
      ,
      'num_range': (panel_class) ->
        $(".#{panel_class} table tbody tr").each () ->
          $this = $(this)
          item_id = $this.find('[data-id]').data('id')
          first = $this.find('.range-input.first').val()
          second = $this.find('.range-input.second').val()
          relation[item_id] = [first, second] if first != "" || second != ""
        relation
      'date_range': (panel_class) ->
        $(".#{panel_class} table tbody tr").each () ->
          $this = $(this)
          item_id = $this.find('[data-id]').data('id')
          if $this.find('.ts-year select:first').val().toString() == "-1" 
            first = null
          else
            first = $this.find('.first .od-time-selector').odTimeSelector('val')

          if $this.find('.ts-year select:last').val().toString() == "-1" 
            second = null
          else
            second = $this.find('.second .od-time-selector').odTimeSelector('val')
          relation[item_id] = [first, second] if first? || second?
        relation
      'address': (panel_class) ->
        $(".#{panel_class} table tbody tr").each () ->
          $this = $(this)
          item_id = $this.find('[data-id]').data('id')
          val = $this.find('.address-slt').odAddressSelector('val')['address']
          relation[item_id] = val if val.length > 0
        relation
    }

    return mapper[name](panel_class)

  # on submit update bind attr
  # $('[name=attribute_bind_form]').submit (e) ->
  $('#submit_bind').click ->
    console.log current_attr
    return submit_bind if not current_attr

    type = current_attr.type
    relation = {}

    # if there is extra relation view
    if render_mapper[type] && question['question_type'] == 0
      relation = generate_relation(render_mapper[type])
    console.log relation
    $.put(location.href, {attribute_id: current_attr['_id'], relation: JSON.stringify(relation)}, () ->
      location.reload()
    )
    false

  $("#delete_bind").click ->
    $this = $(this)
    if confirm "确定要删除吗?"
      $.ajax
        type: 'DELETE'
        url: "/admin/surveys/#{$this.data('id')}/bind_question"
        success: (ret)->
          if ret.success
            alert_msg.show('success', "已经删除!")
            document.location = "/admin/surveys/#{$this.data('id')}/bind_question"
          else
            alert_msg.show('error', "删除失败 (╯‵□′)╯︵┻━┻")
        error: ->
          alert_msg.show('error', "删除失败 (╯‵□′)╯︵┻━┻")
          
