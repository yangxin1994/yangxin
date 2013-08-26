#= require jquery-interdependencies

$ ->

  $('#gift_status').select2
    placeholder: "状态"

  $('#gift_type').select2
    placeholder: "类型"

  $(document).on 'click', '.od-stockin', (e)->
    e.preventDefault()
    self = $(this)
    console.log self
    $.ajax {
      type: 'PUT'
      url: "/admin/gifts/#{$(this).attr('href')}/stockup"
      success: ->
        self.parent().html("已上架")
    }

  $('.searchWidget form').submit () ->
    $this = $(this)
    if $this.find('[name=title]').val() == '按照标题搜索'
      $this.find('[name=title]').val('')

  $(document).on 'click', '.od-outstock', (e)->
    e.preventDefault()
    self = $(this)
    console.log self
    $.ajax
      type: 'PUT'
      url: "/admin/gifts/#{$(this).attr('href')}/outstock"
      success: ->
        self.parent().html("已下架")

  $(document).on 'click', '.od-delete', (e)->
    e.preventDefault()
    self = $(this)
    console.log self
    if confirm "确定要删除吗?"
      console.log e
      $.ajax
        type: 'DELETE'
        url: "/admin/gifts/#{$(this).attr('href')}"
        success: ->
          self.parent().html("已删除")

  # set_rules_for_panels = () ->
  #   build_property_form_rules = (selector) ->
  #     cfg =
  #       hide: (control) ->
  #         control.find('input, textarea, select').attr('disabled', true)
  #         control.hide()
  #       show: (control) ->
  #         control.find('input, textarea, select').attr('disabled', false)
  #         control.show()

  #     ruleset = $.deps.createRuleset()

  #     range_rule = ruleset.createRule '[name="gift[redeem_number][mode]"]', '==','2'
  #     range_rule.include 'div.formRight.number_range'
  #     array_rule = ruleset.createRule '[name="gift[redeem_number][mode]"]', '==', '4'
  #     array_rule.include 'div.formRight.number_ary'

  #     $.deps.enable $(selector), ruleset, cfg

  #   build_property_form_rules '#gift_form'

  # set_rules_for_panels()

  # $('#gift_form').validationEngine()

  # # load data
  # mode = $('#gift_mode').data('mode')
  # console.log mode
  # console.log mode.number_ary
  # $('#gift_mode').val(mode.mode).change()

  # if mode.min
  #   $('[name="gift[redeem_number][min]"]').val(mode.min)
  #   $('[name="gift[redeem_number][max]"]').val(mode.max)
  # else if mode.number_ary.length
  #   $('[name="gift[redeem_number][number_ary]"]').val(mode.number_ary.join(" "))
