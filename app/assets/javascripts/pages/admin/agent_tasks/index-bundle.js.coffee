$ ->
  $('.od-open').click ->
    $this = $(this)
    $.ajax
      data: {}
      url: "/admin/agent_tasks/#{$this.data('id')}/open"
      method: "PUT"
      success: (ret)->
        if ret.success
          $this.closest('span').html("")
          alert_msg.show('success', "操作完成!")
        else
          alert_msg.show('error', "操作失败-#{ret.value.error_code}-#{ret.value.error_code}")
      error: (ret)->
          alert_msg.show('error', "操作失败 (╯‵□′)╯︵┻━┻")

  $('.od-close').click ->
    $this = $(this)
    $.ajax
      data: {}
      url: "/admin/agent_tasks/#{$this.data('id')}/close"
      method: "PUT"
      success: (ret)->
        if ret.success
          $this.closest('span').html("")
          alert_msg.show('success', "操作完成!")
        else
          alert_msg.show('error', "操作失败-#{ret.value.error_code}-#{ret.value.error_code}")
      error: (ret)->
          alert_msg.show('error', "操作失败 (╯‵□′)╯︵┻━┻")
$ ->
  $(document).on 'click', '.od-delete', (e)->
    $this = $(this)
    if confirm "确定要删除吗?"
      $.ajax
        type: 'DELETE'
        url: "/admin/agent_tasks/#{$this.data('id')}"
        success: (ret)->
          if ret.success
            $this.closest('tr').fadeOut()
            alert_msg.show('success', "代理任务已经删除!")
          else
            alert_msg.show('error', "删除失败 (╯‵□′)╯︵┻━┻")
        error: ->
          alert_msg.show('error', "删除失败 (╯‵□′)╯︵┻━┻")