$(->
  $(document).on 'click', '.od-edting',(e)->
    self = $(this)
    $.ajax {
      type: 'POST'
      url: "/admin/ejournals/#{$(this).attr('href')}/deliver"
      success: ->
        self.parent().html("发送中,请稍后查看")
    }
    false
  $(document).on 'click', '.od-delivering',(e)->
    self = $(this)
    $.ajax {
      type: 'DELETE'
      url: "/admin/ejournals/#{$(this).attr('href')}/cancel"
      success: ->
        self.parent().html("已取消")
    }
    false
  $(document).on 'click', '.od-delivered',(e)->
    self = $(this)
    $.ajax {
      type: 'POST'
      url: "/admin/ejournals/#{$(this).attr('href')}/deliver"
      success: ->
        self.parent().html("发送中,请稍后查看")
    }
    false
  $(document).on 'click', '.od-canceled',(e)->
    self = $(this)
    $.ajax {
      type: 'POST'
      url: "/admin/ejournals/#{$(this).attr('href')}/deliver"
      success: ->
        self.parent().html("发送中,请稍后查看")
    }
    false
)