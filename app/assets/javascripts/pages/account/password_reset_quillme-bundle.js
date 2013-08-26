//=require ui/plugins/od_enter

jQuery(function($) {
	function error(msg) {
		$('#error').html(msg || '');
	}

	var btn = $('#ok_btn'), p_ipt = $('#password_ipt'), p2_ipt = $('#password_confirmation_ipt');
	function reset() {
		error(null);
		var password = $.trim(p_ipt.val()), password_repeat = $.trim(p2_ipt.val());
		if(password == '') {
			error('密码不能为空');
			return;
		}
		if(password != password_repeat) {
			error('两次输入的密码不一致');
			return;
		}
		$.util.disable(btn);
		btn.text('正在修改...');
		$.putJSON('/password.json', { 
			key: $.util.param('key'),
			password: password,
			password_confirmation: password_repeat
		}, function(retval) {
			$.util.enable(btn);
			btn.text('修改密码');
			error(retval.success ? '修改密码成功，请用新密码 <a href="/signin">登录</a> 系统。' 
				: '修改密码失败，可能是重置密码链接已过期，您可以 <a href="/password/find">重新发送</a> 重置链接。');
		});
	}

	p_ipt.odEnter({ enter: function() { p2_ipt.focus(); } });
	btn.click(reset);
	p2_ipt.odEnter({ enter: reset });
});
