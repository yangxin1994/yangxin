$ ->
  $.ajaxSetup
    headers: 
      'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')  
  $("#btn_close").click ->
    $this = $(this)
    agent_id = $this.data('task')
    $this.button('loading')
    $.ajax
      url: "/agent/tasks/#{agent_id}/close"
      method: "PUT"
      data:{}
      success: (ret)->
        if ret.success
          alert_msg.show('success', "任务成功关闭")
          $this.button('complete')
        else
          $this.button('reset')
          console.log ret
          alert_msg.show('error', "处理失败,请稍后重试:#{ret.value.error_message} (╯‵□′)╯︵┻━┻ ")
      error: ->
        $this.button('reset')
        alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")
