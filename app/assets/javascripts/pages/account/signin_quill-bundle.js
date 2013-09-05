//=require ui/plugins/od_enter

jQuery(function($) {
	$('#email_ipt').focus(function(){
		$(this).prev().removeClass('icon-mail').addClass('icon-mail2');
	}).blur(function(){
		$(this).prev().removeClass('icon-mail2').addClass('icon-mail');
	}).focus();
	$('#password_ipt').focus(function(){
		$(this).prev().removeClass('icon-i').addClass('icon-i2');
	}).blur(function(){
		$(this).prev().removeClass('icon-i2').addClass('icon-i');
	});

	// function error(msg) {
	// 	$('#error').html(msg || '');
	// }

	var btn = $('#login_btn');
	function login() {
		hideError();
		var email = $.trim($('#email_ipt').val());
		if(!$.regex.isEmail(email)) {
			showError('请输入有效邮箱', '#email_ipt');
			return;
		}
		var password = $('#password_ipt').val();
		if(password == '') {
			showError('密码不能为空', '#password_ipt');
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
				switch(retval.value.error_code) {
					case 'error_11': 
						showError('密码错误，请重新输入密码。', '#password_ipt');
						break;
					case 'error_3':
						showError('此账户尚未激活，请先<a href="/activate/new?e=' + email + '">激活账户</a>。', '#email_ipt');
						break;
					case 'error_4': 
						showError('此邮箱尚未注册，请先<a href="/signup?e=' + email + '">注册</a>。', '#email_ipt');
						break;
					case 'error_24': 
						showError('此邮箱尚未注册，请先<a href="/signup?e=' + email + '">注册</a>。', '#email_ipt');
						break;
					case 'error_100047':
						showError('此用户已被锁定', '#email_ipt');
						break;
					case 'error_10': 
						showError('登录失败，请重试。', btn);
						break;
				}
			}
		});
	}

	$('#email_ipt').odEnter({ enter: function() { $('#password_ipt').focus(); } });
	$('#password_ipt').odEnter({enter: login});
	btn.click(login);
});