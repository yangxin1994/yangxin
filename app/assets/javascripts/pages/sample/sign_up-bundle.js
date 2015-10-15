//=require jquery.placeholder
//=require utility/ajax
//=require base64
$(function() {

	//相应回车提交表单事件
	function submit_form() {
		$('.login_btn').click();
	}

	$('input[name="password_confirmation"]').odEnter({
		enter: submit_form
	});


	var refresh;
	$('.account').blur(function() {
		var account = $(this).val();
		var notice_class = $(this).next().attr('class');
		if ($.regex.isMobile(account)) {
			var code_html = '<div class="identifying_code  wraper">验证码：<br />\
							<input type="text" name="verify_code" class="verify_code"  placeholder="输入手机验证码"  />\
							<button class="send_code disabled" disabled="disabled">免费获取手机验证码</button>\
							<div style="clear:both"></div>\
						</div>'
			if ($('.identifying_code').length < 1) {
				$('#captcha').parents('.wraper').after(code_html);
				//$('.login_password').after(code_html);
				$('input[name="verify_code"]').odEnter({
					enter: submit_form
				});
			}
			//SEND AJAX  REQUEST FOR CHECKING ACCOUNT IF EXIST
			check_account_exist(account, notice_class)
		} else {
			// remove the button  when the account is not a mobile 
			$('.identifying_code').remove();
			if ($.regex.isEmail(account)) {
				//SEND AJAX  REQUEST FOR CHECKING ACCOUNT IF EXIST
				check_account_exist(account, notice_class)
			} else {
				$(this).addClass('error')
				if (notice_class != 'success' && notice_class != 'faild') {
					$(this).after('<span class="faild"></span><span class="notice">请正确输入邮箱或手机号</span>')
				}
			}
		}
	}).focus(function() {
		clear_notice($(this))
	})

	$('input#captcha').blur(function(){
		code = $(this).val();
		check_picture_code(code)
	})

	$('[name="password"]').blur(function() {
		password_check($(this), $(this).val())
	}).focus(function() {
		clear_notice($(this))
	})

	$('[name="password_confirmation"]').blur(function() {
		password_confirmation_check($(this), $(this).val())
	}).focus(function() {
		clear_notice($(this))
	})

	$('input#captcha').blur(function() {
		check_picture_code($(this).val())
	}).focus(function() {
		clear_notice($(this))
	})


	$('.login_btn').click(function() {
		$('span.faild').remove();
		$('span.notice').remove();
		var acc_obj = $('input.account');
		var pass_obj = $('[name="password"]')
		var pass_con_obj = $('[name="password_confirmation"]')
		var pic_obj  = $('input#captcha')
		var pic_value = $.trim(pic_obj.val());
		var code_obj = $('[name="verify_code"]')
		var account = acc_obj.val();
		var password = pass_obj.val();
		var code = code_obj.val();
		var password_confirmation = pass_con_obj.val();
		var notice_class = acc_obj.next().attr('class');


		if ($.regex.isMobile(account) || $.regex.isEmail(account)) {
			if (acc_obj.next('span.success').length < 1) {
				check_account_exist(account, notice_class)
			}
		} else {
			acc_obj.addClass('error')
			if (acc_obj.next('span.faild').length < 1) {
				acc_obj.after('<span class="faild"></span><span class="notice">请正确输入邮箱或手机号</span>');
			}
		}

		password_check(pass_obj, password)
		password_confirmation_check(pass_con_obj, password_confirmation)
		picture_code_check(pic_obj,pic_value)
		verify_code_check(code_obj, code)
		//protocol_check()

		if ($('span.faild').length < 1 && $('span.notice').length < 1) {
			var account = $('input.account').val();
			var pass = $('[name="password"]').val();
			if ($.regex.isEmail(account)) {
				// create a new sample with email
				create_email_sample(account, pass)
			} else {
				var code = $('[name="verify_code"]').val();
				create_mobile_sample(account, pass, code)
			}
		}

	})

	$("img[alt='captcha']").bind('click',function(e){
		this.src = this.src + '?'
		setTimeout(function(){
			$.postJSON('/account/transfer_picture_code.json',{code:true},function(ret){})
		},1000)
		
	})

	function clear_notice(obj) {
		obj.removeClass('error')
		obj.next('span.faild').remove();
		obj.next('span.notice').remove();
		obj.next('span.success').remove();
	}

	function password_check(pass_obj, password) {
		if (password.length < 6 || password.length > 20) {
			pass_obj.addClass('error');
			if (pass_obj.next('span.faild').length < 1) {
				pass_obj.after('<span class="faild"></span><span class="notice">密码长度只能在6-20位字符之间</span>');
			} else {
				pass_obj.next('span.faild').remove();
				pass_obj.next('span.notice').remove();
				pass_obj.after('<span class="success"></span>')
			}
		} else {
			clear_notice(pass_obj)
			pass_obj.after('<span class="success"></span>')
		}
	}


	function picture_code_check(obj,value){
		if (value.length <= 0){
			obj.addClass('error');
			if (obj.next('span.faild').length < 1) {
				obj.after('<span class="faild"></span><span class="notice">请输入验证码</span>');
			} else {
				obj.next('span.faild').remove();
				obj.next('span.notice').remove();
				obj.after('<span class="success"></span>')
			}			
		}else{
			clear_notice(obj);
			obj.after('<span class="success"></span>');
		}
	}


	function password_confirmation_check(confirm_obj, confirmation) {
		if (confirmation.length < 1) {
			confirm_obj.addClass('error');
			if (confirm_obj.next('span.faild').length < 1) {
				confirm_obj.after('<span class="faild"></span><span class="notice">请输入确认密码</span>');
			}
		} else if ((confirmation != $('[name="password"]').val())) {
			confirm_obj.addClass('error')
			if (confirm_obj.next('span.faild').length < 1) {
				confirm_obj.after('<span class="faild"></span><span class="notice">两次输入密码不一致</span>');
			}
		} else {
			clear_notice(confirm_obj)
			confirm_obj.after('<span class="success"></span>')
		}
	}


	function verify_code_check(obj, code) {
		if (obj.length > 0 && code.length < 1) {
			obj.addClass('error')
			if (obj.next('.sned_code').next('span.faild').length < 1) {
				$('.send_code').after('<span class="faild"></span><span class="notice">请输入手机验证码</span>')
			}
		}
	}


	function check_picture_code(code){
		$.postJSON('/account/check_picture_code.json',{code:code},function(retval){
			acc = $.trim($('input.account').val())
			if ($.regex.isMobile(acc)) {
				if (retval.success){
					$('button.send_code').attr('disabled', false).removeClass('disabled');
				}else{
					$('button.send_code').attr('disabled', true).addClass('disabled');
				}
			}else{
				if (retval.success){
					$('input.login_btn').attr('disabled', false).removeClass('disabled');
				}else{
					$('input.login_btn').attr('disabled', true).addClass('disabled');
				}				
			}
		})
	}


	function protocol_check() {
		if ($('.protocol').is(':checked')) {
			clear_notice($('.proto_info'));
		} else {
			if ($('.proto_info').next('span.notice').length < 1) {
				$('.proto_info').parent('span').after('<span class="notice">请接受问卷吧注册用户注册协议</span>')
			}

		}
	}


	function check_account_exist(account, notice_class) {
		$.getJSON('/account/check_user_exist.json', {
			email_mobile: account
		}, function(retval) {
			if (retval.success) {
				if (retval.value['exist']) {
					$('input.account').addClass('error');
					if (notice_class != 'faild') {
						$('input.account').after('<span class="faild"></span><span class="notice">该账户已被注册,请直接登录</span>')
					}
				} else {
					if (notice_class != 'success') {
						$('input.account').removeClass('error')
						$('input.account').next('span.success').remove();
						$('input.account').after('<span class="success"></span>')
						// if ($.regex.isMobile(account)) {
						// 	// when the mobile is correct and not exist enabled the button
						// 	$('button.send_code').attr('disabled', false).removeClass('disabled')
						// }
					}
				}
			} else {
				console.log(' something  went wrong ...')
			}
		})
	}


	$(".send_code").live('click', function() {
		var account = $('.account').val();
		if (account.length > 0 && $.regex.isMobile(account)) {
			send_active_code(account)
		} else {
			$('input.account').addClass('error')
			$('input.account').after('<span class="faild"></span><span class="notice">请输入您的手机号码</span>')
		}
		return false;
	})


	function create_email_sample(email, pass) {
		$('input.login_btn').val('正在注册')
		$('input.login_btn').attr('disabled', true).addClass('disabled')
		$.postJSON('/account/regist.json', {
			email_mobile: email,
			password: pass
		}, function(retval) {
			if (retval.success) {
				window.location.href = "/account/regist_succ?k=" + Base64.encode(email)
			} else {
				$('input.login_btn').attr('disabled', false).removeClass('disabled')
				$('input.login_btn').val('立 即 注 册')
			}
		})
	}

	function create_mobile_sample(account, pass, code) {
		$('input.login_btn').val('正在注册')
		$('input.login_btn').attr('disabled', true).addClass('disabled')
		$.postJSON('/account/mobile_activate.json', {
			mobile: account,
			password: pass,
			verification_code: code
		}, function(retval) {
			if (retval.success) {
				window.location.href = "/account/regist_succ?k=" + Base64.encode(account)
			} else {
				$('input.login_btn').val('立 即 注 册')
				$('input.login_btn').attr('disabled', false).removeClass('disabled')
				generate_error_message(retval.value['error_code'])
			}
		})
	}


	function send_active_code(mobile) {
		$(".send_code").text('正在发送......')
		$('.send_code').attr('disabled', 'disabled').addClass('disabled');
		$.postJSON('/account/regist.json', {
			email_mobile: mobile
		}, function(retval) {
			counter($('.send_code'));
		})
		return false;
	}


	function counter(obj) {
		obj.attr("counter", 60).text("再次发送(60秒)").attr('disabled', 'disabled').addClass('disabled');
		refresh = setInterval(function() {
			var count = parseInt(obj.attr("counter")) - 1
			obj.attr("counter", count)
			obj.text("再次发送(" + count + "秒)");
			if (obj.attr("counter") == 0) {
				clearInterval(refresh)
				obj.text("再次发送").removeAttr('disabled').removeClass('disabled');
			}
		}, 1000);

	}

	function generate_error_message(error_type) {
		switch (error_type) {
			case 'error_5':
				$('.send_code').after('<span class="faild"></span><span class="notice">验证码过期,请重新发送验证码</span>')
				break;
			case 'error_4':
			case 'error_02':
				$('.send_code').after('<span class="faild"></span><span class="notice">验证码不正确</span>')
				break;
		}
	}

})