//=require ui/plugins/od_enter

jQuery(function($) {
	function error(msg) {
		$('#error').text(msg || '');
	}
	$('#username').focus(function(){
		$(this).prev().removeClass('icon-mail').addClass('icon-mail2');
	});
	$('#username').blur(function(){
		$(this).prev().removeClass('icon-mail2').addClass('icon-mail');
	})
	$('#password').focus(function(){
		$(this).prev().removeClass('icon-i').addClass('icon-i2');
		});
	$('#password').blur(function(){
		$(this).prev().removeClass('icon-i2').addClass('icon-i');
	})
	$('#password_repeat').focus(function(){
		$(this).prev().removeClass('icon-o').addClass('icon-o2');
		});
	$('#password_repeat').blur(function(){
		$(this).prev().removeClass('icon-o2').addClass('icon-o');
	});

	$('#open_agreement').click(function() {
		$('#agreement').toggle();
	});

	var reg_btn = $('#reg_btn');
	function register() {
		error(null);
		if(!$('#i_green_protocol').is(':checked')) {
			error('请先阅读并同意注册协议');
			return;
		}
		var email = $.trim($('#reg_username').val());
		var password = $('#reg_password').val(), password_repeat = $('#reg_password_repeat').val();
		if(!$.regex.isEmail(email)) {
			error('请输入有效邮箱');
			return;
		}
		if(password == '') {
			error('密码不能为空');
			return;
		}
		if(password != password_repeat) {
			error('两次输入的密码不一致');
			return;
		}
		$.util.disable(reg_btn);
		reg_btn.text('注册中...');
		$.postJSON('/signup.json', {
			email: email,
			password: password,
			password_confirmation: password_repeat,
			introducer_id: $.trim($.util.param('i')),
			third_party_user_id: $.util.param('tpui')
		}, function(retval) {
			if(retval.success) {
				location.href = '/activate/done?r=true&e=' + encodeURIComponent(email);
			} else {
				$.util.enable(reg_btn);
				reg_btn.text('注 册');
				var msg = null;
				switch(retval.value.error_code) {
					case 'error_17': msg = '邮箱已被注册，请选择其他邮箱。' ; break;
					case 'error_1': msg = '输入的邮箱不合法，请重新输入。' ; break;
					case 'error_18': msg = '邮箱已被注册，请选择其他邮箱。' ; break;
					case 'error_10': msg = '两次输入的密码不一致' ; break;
				}
				error(msg);
			}
		});
	}

	$('#reg_username').odEnter({ enter: function() { $('#reg_password').focus(); } });
	$('#reg_password').odEnter({ enter: function() { $('#reg_password_repeat').focus(); } });
	$('#reg_password_repeat').odEnter({enter: register});
	reg_btn.click(register);

});