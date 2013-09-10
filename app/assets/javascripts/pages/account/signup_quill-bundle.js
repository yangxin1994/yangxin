//=require ui/plugins/od_enter

jQuery(function($) {
	$('#email').focus(function(){
		$(this).prev().removeClass('icon-mail').addClass('icon-mail2');
	});
	$('#email').blur(function(){
		$(this).prev().removeClass('icon-mail2').addClass('icon-mail');
	});
	$('#password').focus(function(){
		$(this).prev().removeClass('icon-i').addClass('icon-i2');
		});
	$('#password').blur(function(){
		$(this).prev().removeClass('icon-i2').addClass('icon-i');
	});
	$('#password_repeat').focus(function(){
		$(this).prev().removeClass('icon-o').addClass('icon-o2');
	});
	$('#password_repeat').blur(function(){
		$(this).prev().removeClass('icon-o2').addClass('icon-o');
	});
	$('#email').focus();

	// toggle contract
	function openProtocol() {
		$('.signup').slideUp('fast');
		$('.protocol').slideDown('fast');
	};
	function closeProtocol() {
		$('.protocol').slideUp('fast');
		$('.signup').slideDown('fast');
	};
	$('#open_protocol').click(openProtocol);
	$('.close_protocol').click(closeProtocol);
	$('#i_green').click(function() {
		if($(this).is(':checked')) {
			$('#i_green_protocol').attr('checked', 'checked');
		} else {
			$('#i_green_protocol').removeAttr('checked');
		}
		closeProtocol();
	});
	$('#i_green_protocol').click(function() {
		if($(this).is(':checked')) {
			$('#i_green').attr('checked', 'checked');
		} else {
			$('#i_green').removeAttr('checked');
		}
	});

	// register
	var reg_btn = $('#reg_btn');
	function register() {
		hideError();
		var email = $.trim($('#email').val());
		if(!$.regex.isEmail(email)) {
			showError('请输入有效邮箱', '#email');
			return;
		}
		var password = $('#password').val(), password_repeat = $('#password_repeat').val();
		if(password == '') {
			showError('密码不能为空', '#password');
			return;
		}
		if(password != password_repeat) {
			showError('两次输入的密码不一致', '#password_repeat');
			return;
		}
		if(!$('#i_green_protocol').is(':checked')) {
			showError('请先阅读并同意注册协议', $('#i_green_protocol').parent());
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
				switch(retval.value.error_code) {
					case 'error_17': showError('邮箱已被注册，请选择<a href="/signin?e=' + encodeURIComponent(email) + '">直接登录</a>。', '#email'); break;
					case 'error_1': showError('输入的邮箱不合法，请重新输入。', '#email'); break;
					case 'error_18': showError('邮箱已被注册，请选择<a href="/signin?e=' + encodeURIComponent(email) + '">直接登录</a>。', '#email'); break;
					case 'error_10': showError('两次输入的密码不一致', '#password_repeat'); break;
				}
			}
		});
	}

	$('#email').odEnter({ enter: function() { $('#password').focus(); } });
	$('#password').odEnter({ enter: function() { $('#password_repeat').focus(); } });
	$('#password_repeat').odEnter({enter: register});
	reg_btn.click(register);
});