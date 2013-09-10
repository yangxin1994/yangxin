//=require ui/plugins/od_enter

jQuery(function($) {
	function error(msg) {
		$('#error').html(msg || '');
	}

	var btn = $('#login_btn');
	function login() {
		error(null);
		var email = $.trim($('#email_ipt').val());
		if(!$.regex.isEmail(email)) {
			error('请输入有效邮箱');
			return;
		}
		var password = $('#password_ipt').val();
		if(password == '') {
			error('密码不能为空');
			return;
		}
		$.util.disable(btn);
		btn.text('登录中...');
		$.postJSON('/signin.json', {
			email: email,
			password: password,
			permanent_signed_in: $('#remember_ckb').is(':checked'),
			third_party_user_id: $.util.param('tpui')
		}, function(retval) {
			if(retval.success) {
				location.reload(true);
			} else {
				$.util.enable(btn);
				btn.text('登 录');
				var msg = null;
				switch(retval.value.error_code) {
					case 'error_11': msg = '密码错误，请重新输入密码。' ; break;
					case 'error_3': msg = '您的账户尚未激活，请先 <a href="/activate/new?e=' + email + '">激活账户</a> 。' ; break;
					case 'error_4': msg = '此邮箱尚未注册，请先 <a href="/signup?e=' + email + '">注册</a> 。' ; break;
					case 'error_24': msg = '此邮箱尚未注册，请先 <a href="/signup?e=' + email + '">注册</a> 。' ; break;
					case 'error_10': msg = '登录失败，请重试' ; break;
				}
				error(msg);
			}
		});
	}

	$('#email_ipt').odEnter({ enter: function() { $('#password_ipt').focus(); } });
	$('#password_ipt').odEnter({enter: login});
	btn.click(login);
});