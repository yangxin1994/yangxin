$ ->

  $.ajaxSetup
    headers: 
      'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')  
  review = (is_pass, message_content, _this)->
    $this = $(_this)
    $.ajax
      url: "/agent/answers/#{$this.data("answer_id")}"
      method:"PUT"
      data:
        agent_task_id: querilayer.queries.agent_task_id
        review_result: is_pass
        message_content: message_content
      success: (ret)->
        if ret.success
          $this.closest('span').html("")
          alert_msg.show('success', "操作完成!")
        else
          alert_msg.show('error', "操作失败-#{ret.value.error_code}-#{ret.value.error_code}")
      error: (ret)->
          alert_msg.show('error', "操作失败 (╯‵□′)╯︵┻━┻")

  $("#btn_reject").click ->
    if remark = prompt("请输入拒绝理由", "答题不认真")
      alert_msg.show('info', "处理中, 请稍后...")
      $('html,body').animate({scrollTop: $('body').offset().top}, 300)
      review(false, remark, this)
  $("#btn_pass").click ->
    alert_msg.show('info', "处理中, 请稍后...")
    $('html,body').animate({scrollTop: $('body').offset().top}, 300)
    review(true, "", this)
