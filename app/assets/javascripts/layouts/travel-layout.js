$(function(){
	$('.user-panel input').focus(function(){
	$('span.notice').remove();
	})
	$('.login-btn').click(function(){
		var email = $.trim($('#login_email').val());
		var pwd   = $.trim($('#login_password').val());
		if(email.length > 0 && pwd.length > 0){
        	$('.login-btn').html('登录中')
        	$('.login-btn').attr('disabled', true).addClass('disabled')
        	$.postJSON('/account/login.json', {
        	    email_mobile: email,
        	    password: pwd
        	}, function(retval) {
        	    if (retval.success) {
        	        location.href = '/account/after_sign_in' + ($.util.param('ref') ? ('?ref=' + $.util.param('ref')) : '');
        	    } else {
        	        $('.login-btn').attr('disabled', false).removeClass('disabled')
        	        $('.login-btn').html('登录')
        	        generate_error_message(retval.value['error_code'])
        	    }
        	})


		}
	})

    function generate_error_message(error_type) {
        var err_notice = null
        switch (error_type) {
            case 'error_3':
                err_notice = "<span class='notice'>账户未激活</span>"
                break;
            case 'error_4':
                err_notice = "<span class='notice'>账户不存在</span>"
                break;
            case 'error_11':
                err_notice = "<span class='notice'>密码错误</span>"
                break;
            case 'error_24':
                err_notice = "<span class='notice'>账户未注册</span>"
                break;
        }
        if (error_type == 'error_11') {
            if ($('[name="password"]').next('span.faild').length < 1) {
                $('[name="password"]').after(err_notice);
            }
        } else {
            if ($('[name="email"]').next('span.faild').length < 1) {
                $('[name="email"]').after(err_notice);
            }
        }

    }


})