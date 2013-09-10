//=require ui/plugins/od_enter

jQuery(function($) {
	$('#password_ipt').focus(function(){
		$(this).prev().removeClass('icon-i').addClass('icon-i2');
	}).blur(function(){
		$(this).prev().removeClass('icon-i2').addClass('icon-i');
	})
	$('#password_confirmation_ipt').focus(function(){
		$(this).prev().removeClass('icon-o').addClass('icon-o2');
	}).blur(function(){
		$(this).prev().removeClass('icon-o2').addClass('icon-o');
	});
	$('#password_ipt').focus();

	function error(msg) {
		hideError();
		$('#error .error-prompt-txt').html(msg);
		$('#error').fadeIn('fast');
	};
	function hideError() {
		$(this).parents('#error').hide();
	};
	$('#error .close-error').click(hideError);

	var btn = $('#ok_btn'), p_ipt = $('#password_ipt'), p2_ipt = $('#password_confirmation_ipt');
	function reset() {
		hideError();
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
			if(retval.success) {
				$('#input_con').slideUp();
				$('#success').fadeIn('fast');
			} else {
				error('链接已过期，需要重新 <a href="/password/find">重置密码</a>。');
			}
		});
	}

	p_ipt.odEnter({ enter: function() { p2_ipt.focus(); } });
	btn.click(reset);
	p2_ipt.odEnter({ enter: reset });
});