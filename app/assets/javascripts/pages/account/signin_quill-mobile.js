jQuery(function($) {
	var loginString = '<a href="signin?m=true&ref=' + window.location.href + '" >登录</a>';
	console.log(loginString);

	var btn = $('#login_btn');
	function login() {
		var email = $.trim($('#email_ipt').val());
		if(!$.regex.isEmail(email)) {
			showError("请输入有效邮箱");
			return;
		}
		var password = $('#password_ipt').val();
		if(password == '') {
			showError("密码不能为空");
			return;
		}
		$.util.disable(btn);
		btn.text('登录中...');
		$.postJSON('/signin.json', {
			email: email,
			password: password,
			permanent_signed_in: $('#remember_ckb').is(':checked')
		}, function(retval) {
			if(retval.success) {
				location.reload(true);
			} else {
				$.util.enable(btn);
				btn.text('登 录');
				switch(retval.value.error_code) {
					case 'error_11': 
						showError('密码错误，请重新输入密码。');
						break;
					case 'error_3':
						showError('此账户尚未激活，请先<a href="/activate/new?e=' + email + '">激活账户</a>。');
						break;
					case 'error_4': 
						showError('此邮箱尚未注册，请先<a href="/signup?e=' + email + '">注册</a>。');
						break;
					case 'error_24': 
						showError('此邮箱尚未注册，请先<a href="/signup?e=' + email + '">注册</a>。');
						break;
					case 'error_100047':
						showError('此用户已被锁定');
						break;
					case 'error_10': 
						showError('登录失败，请重试。');
						break;
				}
			}
		});

		function showError(msg) {
			$("#error_msg").html(msg);
			$("#error_msg").show();			
		}
	}

	btn.click(login);
});