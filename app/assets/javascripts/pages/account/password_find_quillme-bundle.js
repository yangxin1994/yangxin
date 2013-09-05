//=require ui/plugins/od_enter

jQuery(function($) {
	function error(msg) {
		$('#error').html(msg || '');
	}
	var btn = $('#find_btn'), ipt = $('#email_ipt');
	function send() {
		error(null);
		var email = $.trim(ipt.val());
		if(!$.regex.isEmail(email)) {
			error('请输入有效邮箱');
			return;
		}
		$.util.disable(btn);
		btn.text('发送中...');
		$.postJSON('/password/send_reset_email.json', { email: email }, function(retval) {
			$.util.enable(btn);
			btn.text('重置密码');
			if(retval.success) {
				error('重置密码链接已经发送至您的邮箱，请在 24 小时内登录邮箱，打开重置密码的链接进行重置密码。');
			} else {
				error('发送激活邮件失败，请确保您输入了有效的注册邮箱，如果邮箱未注册，请先注册。');
			}
		});
	}

	btn.click(send);
	ipt.odEnter({ enter: send });
});