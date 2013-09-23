$ ->
  $(document).on 'click', '.od-delete', (e)->
    $this = $(this)
    if confirm "确定要删除吗?"
      $.ajax
        type: 'DELETE'
        url: "/admin/subscribers/#{$(this).data('id')}"
        success: (ret)->
          if ret.success
            $this.closest('tr').fadeOut()
            alert_msg.show('success', "订阅已经删除!")
          else
            alert_msg.show('error', "删除失败 (╯‵□′)╯︵┻━┻")
        error: ->
          alert_msg.show('error', "删除失败 (╯‵□′)╯︵┻━┻")

  $('.od-subscribe').click (e)->
    $this = $(this)
    $.ajax
      type: 'PUT'
      url: "/admin/subscribers/#{$(this).data('id')}/subscribe"
      success: (ret)->
        if ret.success
          $this.addClass 'disabled'
          $this.html("已开始推送")
          $this.unbind('click')
          alert_msg.show('success', "系统将对该用户的推送杂志!")
        else
          alert_msg.show('error', "操作失败 (╯‵□′)╯︵┻━┻")
      error: ->
        alert_msg.show('error', "操作失败 (╯‵□′)╯︵┻━┻")

  $('.od-unsubscribe').click (e)->
    $this = $(this)
    if confirm "确定要停止对该用户的推送吗?"
      $.ajax
        type: 'PUT'
        url: "/admin/subscribers/#{$(this).data('id')}/unsubscribe"
        success: (ret)->
          if ret.success
            $this.addClass 'disabled'
            $this.html("已停止推送")
            $this.unbind('click')
            alert_msg.show('success', "成功停止对该用户的推送!")
          else
            alert_msg.show('error', "操作失败 (╯‵□′)╯︵┻━┻")
        error: ->
          alert_msg.show('error', "操作失败 (╯‵□′)╯︵┻━┻")

  $('#send_list').click ->
    $('#message_modal').modal('hide');
    alert_msg.show('info', "正在添加,请稍后...")
    $.ajax
      url: "/admin/subscribers"
      method: 'POST'
      data:
        subscribers: $('#mail_list').val()
      success: (ret)->
        if ret.success
          console.log ret
          alert_msg.show('success', "操作完成!成功添加#{ret.value.s_count}个!重复#{ret.value.e_count}个!失败#{ret.value.f_count}个!")
        else
          console.log ret
          alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")
      error: ->
          alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")
