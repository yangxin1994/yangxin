$ ->
  samples = new CheckList

  $('.check-sample').click ->
    $this = $(this)
    if $this.prop('checked')
      samples.add($this.val())
    else
      samples.remove($this.val())

  $('#send_message').click ->
    $('#message_modal').modal('hide');
    alert_msg.show('info', "正在发送,请稍后...")
    $.ajax
      url: "/admin/samples/send_message"
      method: 'POST'
      data:
        sample_ids: samples.selected
        title: $('#message_title').val()
        content: $('#message_content').val()
      success: (ret)->
        if ret.success
          alert_msg.show('success', "操作完成!")
        else
          console.log ret
          alert_msg.show('error', "处理失败,请稍后重试")
      error: ->
          alert_msg.show('error', "处理失败,请稍后重试")

  $(".roles").click ->
    $("#a_mobile_p").hide()
    $(".ck").prop("checked", false)
    $this = $(this).closest('td')
    window.current_$ = $this
    $("#sid").val $this.data("sid")
    $("#i_email").val $this.data("email")
    $("#i_mobile").val $this.data("mobile")

    $("#a_email").prop("checked", true) if $this.data("a_email") == true
    $("#a_mobile").prop("checked", true) if $this.data("a_mobile") == true
    $("#a_mobile_p").show() if !$this.data("a_mobile_p")
    $("#ck_block").prop("checked", true) if $this.data("is_blcok") == true

    $("#ck_sample").prop("checked", true) if $this.data("roles") & 1
    $("#ck_guest").prop("checked", true) if $this.data("roles") & 2
    $("#ck_admin").prop("checked", true) if $this.data("roles") & 4
    $("#ck_survey").prop("checked", true) if $this.data("roles") & 8
    $("#ck_interviewer").prop("checked", true) if $this.data("roles") & 16
    $('#roles_modal').modal('show')

  $('#send_roles').click ->
    $('#roles_modal').modal('hide')
    sample_id = $("#sid").val()
    alert_msg.show('info', "正在处理,请稍后...")
    _block = $("#ck_block").prop("checked")
    _a_email = $("#a_email").prop("checked")
    _a_mobile = $("#a_mobile").prop("checked")
    _a_mobile_p = _a_mobile && $("#i_psw").val()

    roles = []
    roles.push(1)  if $("#ck_sample").prop("checked")
    roles.push(2)  if $("#ck_guest").prop("checked")
    roles.push(4)  if $("#ck_admin").prop("checked")
    roles.push(8)  if $("#ck_survey").prop("checked")
    roles.push(16)  if $("#ck_interviewer").prop("checked")

    $.ajax
      url: "/admin/samples/#{sample_id}/set_sample_role"
      method: 'PUT'
      data:
        block: _block
        roles: roles
        email: $("#i_email").val()
        email_activation: _a_email
        mobile: $("#i_mobile").val()
        mobile_activation: _a_mobile
        password: $("#i_psw").val()
      success: (ret)->
        if ret.success
          console.log ret
          window.current_$.data("is_blcok", _block)
          window.current_$.data("a_email", _a_email)
          window.current_$.data("a_mobile", _a_mobile)
          window.current_$.data("roles", roles.sum())
          window.current_$.data("a_mobile_p", _a_mobile_p)
          alert_msg.show('success', "操作完成!")
        else
          console.log ret
          alert_msg.show('error', "处理失败,请稍后重试")        
      error: ->
          alert_msg.show('error', "处理失败,请稍后重试")

  $('#send_list').click ->
    $('#point_modal').modal('hide');
    alert_msg.show('info', "正在处理,请稍后...")
    $.ajax
      url: "/admin/samples/#{sample_id}/block"
      method: 'PUT'
      data:
        sample_ids: samples.selected
        title: $('#message_title').val()
        content: $('#message_content').val()
      success: (ret)->
        if ret.success
          alert_msg.show('success', "操作完成!")
        else
          console.log ret
          alert_msg.show('error', "处理失败,请稍后重试")        
      error: ->
          alert_msg.show('error', "处理失败,请稍后重试")   