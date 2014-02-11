#=require jquery.fancybox.pack
#=require ui/plugins/od_enter
#=require utility_admin/querilayer

$ ->

  # =========================
  submit_form = () ->
    $('.login_btn').click();

  show_error_msg = (msg, selector = nil) ->    
    $(".error_msg").html(msg).show()
    $(selector).addClass("error") if selector

  clean_error_msg = (selector = nil)->
    $(".error_msg").html("").hide()
    $(selector).removeClass("error") if selector

  email_reg = new RegExp(/^([a-zA-Z0-9]+[_|\_|\.]?)*[a-zA-Z0-9]+@([a-zA-Z0-9]+[_|\_|\.]?)*[a-zA-Z0-9]+\.[a-zA-Z]{2,3}$/)

  email_auto_complete = (email)->
    email_list = ["qq.com", "163.com", "126.com", "gmail.com", "sina.com", "live.com"]
    tip_email = ""
    flag = email_reg.test(item)
    e_1 = email.split("@")[0]
    e_2 = email.split("@")[1]
    for item in email_list
       if e_2
          if item.indexOf(e_2) != -1

            tip_email += "<li><a href=\"javascript:;\">#{e_1}@#{item}</a></li>"
          else
            e_2_1 = e_2.split('.')[0]
            tip_email = "<li><a href=\"javascript:;\">#{e_1}@#{e_2_1}.com</a></li>"
            tip_email += "<li><a href=\"javascript:;\">#{e_1}@#{e_2_1}.com.cn</a></li>"
            tip_email += "<li><a href=\"javascript:;\">#{e_1}@#{e_2_1}.cn</a></li>"
       else
          tip_email += "<li><a href=\"javascript:;\">#{e_1}@#{item}</a></li>"
    
    $(".tip-panel").html(tip_email).show()


  find_password = ->
    $('.forget-password button').click()

  send_ajax_request =(mail,ipt,tip,btn)->
    btn.removeClass('finished').addClass('sending').html('<img src="/assets/home/mail-loading.gif">')
    start_time = new Date().getTime()
    $.postJSON('/accounts/forget_password.json',{email:mail}, (retval)->
      if retval.success
        if mail.indexOf('gmail.com') > -1 
          mail_to = 'http://gmail.com'
        else if mail.indexOf('@tencent.') > -1
          mail_to = 'http://mail.qq.com'
        else if mail.indexOf('@qq.') > -1 
          mail_to = 'http://mail.qq.com'
        else 
          mail_to = 'http://mail.' + mail.split('@')[1]

        end_time =  new Date().getTime()
        if (end_time - start_time) > 2000
          tip.html("发送成功,<a href='#{mail_to}'>查收邮件</a>")
          btn.removeClass('sending').addClass('finished').html('已发送')
        else
          setTimeout(->
            tip.html("发送成功,<a href='#{mail_to}'>查收邮件</a>")
            btn.removeClass('sending').addClass('finished').html('已发送')
          , 2000 - (end_time - start_time) )
      else
        btn.removeClass('sending').html('发送')
        ipt.addClass('error').val(mail)
        tip.text('该账户不存在').addClass('red')

    )



  # =========================

  # Placeholder 控制
  $('.login-reg-r').on "focus", "input", ->
    $this = $(this)
    $this.addClass("focus")

  $('.login-reg-r').on "blur", "input", ->
    $this = $(this)
    if !!!$this.val()
      $this.removeClass("focus")

  # 邮箱自动补全

  $(".tip-panel").hide()

  $("#reg-username").keyup (event)->
    $this = $(this)
    key_code = event.keyCode
    if email_reg.test($this.val())
      clean_error_msg("#reg-username") 
      $(".tip-panel").hide()
    else
      # email_auto_complete($this.val())
      # if (keyCode == 40)
        
      # if (keyCode == 38)
      #   # up
      # if (keyCode == 13)
      #   # enter
      # if (keyCode == 27)
        # esc
    if !$this.val()
      $(".tip-panel").hide()

  $(".tip-panel").on "click", "a", ->
    $this = $(this)
    $("#reg-username").val($this.html())
    clean_error_msg("#reg-username")
    $(".tip-panel").hide()

  # 注册按钮事件
  $(".error_msg").hide()

  $(".submit-reg").click ->
    $this = $(this)
    if $this.hasClass("disabled") 
      return false
    else
      unless $("#reg-username").val()
        show_error_msg("请填写邮箱。", "#reg-username")
        $("#reg-username").focus()
        return false
      unless $("#reg-password").val()
        show_error_msg("请填写密码。", "#reg-password")
        $("#reg-password").focus()
        return false
      
      $this.addClass("disabled")
      _username = $("#reg-username").val()
      _password = $("#reg-password").val()
      $.ajax
        url: "/accounts/regist"
        type: "POST"
        data:
          username: _username
          password: _password
        success: (ret)->
          if ret.success
            $.ajax
              url: "/accounts/login"
              type: "POST"
              data:
                username: _username
                password: _password
              success: ->
                document.location.href = querilayer.queries.ref || "/questionaires"
          else
            $this.removeClass("disabled")
            switch ret.value.error_code
              when 'error_25'
                show_error_msg("该邮箱已经注册过，请直接登陆。", "#reg-username")
              when 'error___2'
                show_error_msg("邮箱格式不正确。", "#reg-username")
              else
               
        error: ->
          $this.removeClass("disabled")
    false

  # 登陆按钮事件
  $(".submit-login").click ->
    $this = $(this)
    if $this.hasClass("disabled") 
      return false
    else
      unless $("#login-username").val()
        show_error_msg("请填写邮箱。", "#login-username")
        $("#login-username").focus()
        return false
      unless $("#login-password").val()
        show_error_msg("请填写密码。", "#login-password")
        $("#login-password").focus()
        return false    
      $this.addClass("disabled")
      $.ajax
        url: "/account/login"
        type: "POST"
        data:
          email_mobile: $("#login-username").val()
          password: $("#login-password").val()
          permanent_signed_in: $("#keep_signin").hasClass("active")
        success: (ret)->
          console.log ret
          if ret.success
            document.location.href = querilayer.queries.ref || "/questionaires"
          else
            $this.removeClass("disabled")
            switch ret.value.error_code 
              when "error___2"
                show_error_msg("邮箱格式不正确。", "#login-username")
              when "error_e00007"
                show_error_msg("密码错误。", "#login-password")
              when "error_11"
                show_error_msg("密码错误。", "#login-password")
              when "error_4"
                show_error_msg("没有该用户。", "#login-username")
              else
                # ...
        error: ->
          $this.removeClass("disabled")
    false

  # 登录注册切换
  $("#cto_signup").click ->
    $(".reg").show()
    $(".login").hide()

  $("#cto_signin").click ->
    if $("#login-username").val() == "" && $("#reg-username").val() != ""
      $("#login-username").addClass("focus").val($("#reg-username").val())
    if $("#login-password").val() == "" && $("#reg-password").val() != ""
      $("#login-password").addClass("focus").val($("#reg-password").val())    
    $(".login").show()
    $(".reg").hide()

  $(".remember").click ->
    $this = $("#keep_signin")
    if $this.hasClass("active")
      $this.removeClass("active")
    else
      $this.addClass("active")
    

  $('.forget-pw').click(->
    $.fancybox.open($('.forget-password'),{
        padding:0,
        autoSize:true,
        scrolling:no,
        openEffect:'none',
        closeEffect:'none',        
        helpers : {
          overlay : {
            locked: false,
            closeClick: false,
            css : {
              'background' : 'rgba(51, 51, 51, 0.2)'
            }
          }
        },
      afterClose:-> 
        $('input[name="email"]').val('')
        $('.tip').text('').removeClass('red')
        $('.forget-password button').removeAttr('class')
    })
  )

  # forget password related
  ipt = $('input[name="email"]')
  tip = $('.tip')
  $('.forget-password button').click(->
    btn = $(@)
    email = ipt.val()
    unless $.regex.isEmail(email)
      ipt.addClass('error')
      tip.text('邮箱格式错误,请重新输入').addClass('red')
    else
      ipt.removeClass('error')
      tip.text('').removeClass('red')
      send_ajax_request(email,ipt,tip,btn)
  )

  ipt.focus(->
    ipt.removeClass('error')
    tip.text('').removeClass('red')
  )

  $('input[name="email"]').odEnter({
    enter: find_password
  });



