$(->
  $(document).on 'click', '.od-resubscribe-btn',(e)->
    self = $(this)
    $.ajax {
      type: 'PUT'
      url: "/admin/subscribers/#{$(this).attr('href')}/subscribe"
      success: ->
        self.parent().html("已重新添加")
    }
    false
  $(document).on 'click', '.od-unsubscribe-btn',(e)->
    self = $(this)
    $.ajax {
      type: 'PUT'
      url: "/admin/subscribers/#{$(this).attr('href')}/unsubscribe"
      success: ->
        self.parent().html("已取消订阅")
    }
    false
  $(document).on 'click', '#od-search-btn',(e)->
    self = $(this)
    $.ajax {
      type: 'GET'
      data:
        s:        $('#od-search-ipt').val(),
        partial:  true
      url: "/admin/subscribers"
      success: (val)->
        $("#tab-all").click()
        $("#all").html(val)
    }
    false
  $(document).on 'click', '.od-subscribe-btn',(e)->
    self = $(this)
    $.ajax {
      data: subscribers: $('#od-subscribe-ipt').val()
      type: 'POST'
      url: "/admin/subscribers"
      success: (e)->
        f_count = e.value.f_count
        s_count = e.value.s_count
        e_count = e.value.e_count
        $('.od-subscribe-rst:first').before("<p class=\"od-subscribe-rst\" style=\"display:none\" >成功添加 #{s_count} 条, 另有 #{e_count} 条重复 , #{f_count} 条格式错误</p>" )
                                    .prev()
                                    .fadeIn()
    }
    false
  $(document).on 'click', '.od-delete-btn',(e)->
    self = $(this)
    $.ajax {
      type: 'DELETE'
      url: "/admin/subscribers/#{$(this).attr('href')}"
      success: ->
        self.parent().html("已删除")
    }
    false
  false
)