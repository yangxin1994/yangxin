//=require base64
$(function() {

  //相应回车提交表单事件
  function submit_form() {
    $('button.next').click();
  }
  $('div.acc input').odEnter({
    enter: submit_form
  });

  var params = null;
  var uri = decodeURIComponent(window.location.href)
  if (uri.indexOf('?') > -1) {
    if (uri.indexOf('?key=') > -1) {
      params = uri.substring(uri.indexOf('?') + 5, uri.length);
    } else {
      params = uri.substring(uri.indexOf('?') + 3, uri.length);
    }

    if (uri.indexOf('?acc') <= 0) {
      var acc = Base64.decode(params);
      if ($.regex.isMobile(acc)) {
        window.forget_mobile = acc
        counter($('.send_code'));
      } else if ($.regex.isEmail(acc)) {
        if (acc.indexOf('gmail.com') > -1) {
          var mail_to = 'http://gmail.com';
        } else if (acc.indexOf('@tencent.') > -1) {
          var mail_to = 'http://mail.qq.com';
        } else if (acc.indexOf('@qq.') > -1) {
          var mail_to = 'http://mail.qq.com';
        } else {
          var mail_to = 'http://mail.' + acc.split('@')[1];
        }
        $('button.second').attr('data', mail_to)
        $('button.next').text('马上激活');
      }
    }

  }

  $('input').focus(function() {
    $(this).removeClass('error')
    $(this).next('span.notice').remove();
  })

  $('button.next').click(function() {
    if ($(this).hasClass('first')) {
      var v = $('input[name="account"]').val();
      window.forget_mobile = v
      if (v.length < 1) {
        $('input[name="account"]').addClass('error')
      } else if (!$.regex.isMobile(v) && !$.regex.isEmail(v)) {
        $('input[name="account"]').addClass('error')
      } else {
        send_activate_code($(this), v)
      }
    } else if ($(this).hasClass('second')) {
      var mail_to = $(this).attr('data')
      if (typeof mail_to !== 'undefined' && mail_to !== false) {
        window.location.href = mail_to
      } else {
        var code = $('input[name="verify_code"]').val()
        //根据验证码判断是否可以跳转到第三步
        check_activate_code(code)

      }
    } else if ($(this).hasClass('third')) {
      var pass = $('input[name="password"]').val();
      var pass_confirm = $('input[name="password_confirmation"]').val();
      if (pass == pass_confirm) {
        generate_new_password(window.forget_account, pass)
      } else {
        $('input[name="password_confirmation"]').after("<span class='notice'>确认密码不正确</span>")
      }

    }

  })


  $(".send_code").on('click', function() {
    $(this).text('正在发送......')
    $('.second p span').text('正在发送......')
    $(this).attr('disabled', 'disabled')
    send_activate_code($(this), window.forget_mobile)
    return false;
  })

  $('a.re_mail').click(function() {
    var mail = $(this).attr('account')
    re_mail(mail)
  })


  function re_mail(mail) {
    $.getJSON('/account/send_forget_pass_code.json', {
      email_mobile: mail
    }, function(retval) {
      if (retval.success) {
        if ($('a.re_mail').next('i').length < 1) {
          $('a.re_mail').after('<i><img src="/assets/od-quillme/success.png"/></i>')
        }
      } else {
        generate_error_message(retval.value['error_code'])
      }
    })
    return false;
  }

  function send_activate_code(button, account) {
    $.getJSON('/account/send_forget_pass_code.json', {
      email_mobile: account
    }, function(retval) {
      if (retval.success) {
        if (!button.hasClass('send_code')) {
          window.location.href = window.location.href + '?k=' + Base64.encode(account)
        } else {
          $('.second p span').text('手机验证码已发送')
        }
      } else {
        generate_error_message(retval.value['error_code'])
      }
      counter($('.send_code'));
    })
    return false;
  }

  function generate_error_message(error_type) {
    var err_notice = ''
    switch (error_type) {
      case 'error_3':
        err_notice = "<span class='notice'>账户未激活,您可以<a href='/account/sign_up'>重新激活</a></span>"
        break;
      case 'error_4':
        err_notice = "<span class='notice'>账户不存在</span>"
        break;
      case 'error_24':
        err_notice = "<span class='notice'>账户未激活,您可以<a href='/account/sign_up'>重新激活</a></span>"
        break;
    }
    if ($('[name="account"]').next('span.notice').length < 1) {
      $('[name="account"]').after(err_notice);
    }

  }

  function generate_new_password(account, password) {
    $.getJSON('/account/generate_new_password.json', {
      email_mobile: account,
      password: password
    }, function(retval) {
      if (retval.success) {
        window.location.href = window.location.href.split('?')[0] + "?acc=" + Base64.encode(account)
      }
    })
    return false;
  }



  function counter(obj) {
    obj.attr("counter", 60).text("再次发送(60秒)").attr('disabled', 'disabled');
    var refresh = setInterval(function() {
      var count = parseInt(obj.attr("counter")) - 1
      obj.attr("counter", count)
      obj.text("再次发送(" + count + "秒)");
      if (obj.attr("counter") == 0) {
        clearInterval(refresh)
        obj.text("再次发送").removeAttr('disabled');
      }
    }, 1000);
  }



  function check_activate_code(code) {
    if (/^\d{6}$/.test(code)) {
      make_forget_pass_activate(window.forget_mobile, code)
    } else {
      $('input[name="verify_code"]').addClass('error')
    }
  }

  function make_forget_pass_activate(mobile, code) {
    $.getJSON('/account/forget_pass_mobile_activate.json', {
      phone: mobile,
      code: code
    }, function(retval) {
      if (retval.success) {
        window.location.href = window.location.href.split('?')[0] + '?k=' + Base64.encode(mobile) + '&c=' + Base64.encode(code)
      } else {
        if ($('div.notice').length < 1) {
          $('<div class="notice expire">验证码不正确或超时,请重新发送</div>').appendTo('div.identifying_code')
        }
      }
    })
    return false;
  }

})