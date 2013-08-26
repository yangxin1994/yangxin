//=require ui/plugins/od_enter

jQuery(function($) {
	$('#email_ipt').focus(function(){
		$(this).prev().removeClass('icon-mail').addClass('icon-mail2');
	}).blur(function(){
		$(this).prev().removeClass('icon-mail2').addClass('icon-mail');
	});
	$('#email_ipt').focus();

	function error(msg) {
		hideError();
		$('#error .error-prompt-txt').html(msg);
		$('#error').fadeIn('fast');
	};
	function hideError() {
		$(this).parents('#error').hide();
	};
	$('#error .close-error').click(hideError);

	var btn = $('#find_btn'), ipt = $('#email_ipt');
	function send() {
		hideError();
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
				$('#input_con').slideUp();
				$('.mail-address').text(email);
				$('#success').fadeIn('fast');
			} else {
				error('此邮箱尚未注册。');
			}
		});
	}

	btn.click(send);
	ipt.odEnter({ enter: send });
});