//=require ui/plugins/od_enter

jQuery(function($) {
	function error(msg) {
		$('#error').html(msg || '');
	}

	var btn = $('#activate_btn'), ipt = $('#activate_ipt');
	function activate() {
		error(null);
		var email = $.trim(ipt.val());
		if(!$.regex.isEmail(email)) {
			error('请输入有效邮箱');
			return;
		}
		$.util.disable(btn);
		btn.text('激活中...');
		$.postJSON('/activate.json', { email: email }, function(retval) {
			if(retval.success) {
				location.href = '/activate/done?e=' + encodeURIComponent(email);
			} else {
				$.util.enable(btn);
				btn.text('激活账户');
				var msg = null;
				switch(retval.value.error_code) {
					case 'error_4': msg = '此邮箱尚未注册，<a href="/signup?e=' + email + '">现在注册</a> 。' ; break;
					case 'error_24': msg = '此邮箱尚未注册，<a href="/signup?e=' + email + '">现在注册</a> 。' ; break;
					case 'error_2': msg = '账户已激活，您可以直接 <a href="/signup?e=' + email + '">登录系统</a> 。' ; break;
					default: msg = '发送激活邮件失败，请重试。' ; break;
				}
				error(msg);
			}
		});
	}

	btn.click(activate);
	ipt.odEnter({ enter: activate });
});