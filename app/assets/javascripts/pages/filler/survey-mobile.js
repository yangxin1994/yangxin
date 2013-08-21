jQuery(function($) {
	// add spreadable dom
	$('#sf_main .copyright').before(window.spread_dom);

	var start_btn = $('#start_btn'), email_ipt = $('#email_ipt'),
			username_ipt = $('#username_ipt'), password_ipt = $('#password_ipt');
	var _start = function(after_login) {
		// set start button text
		var new_text = (after_login ? '登录成功，' : '') + '正在加载问题...';
		if(username_ipt.length > 0) {
			new_text = '正在验证用户名密码...';
		} else if(password_ipt.length > 0) {
			new_text = '正在验证密码...';
		}
		start_btn.text(new_text);
		// disable inputs
		$.util.disable(start_btn, email_ipt, username_ipt, password_ipt);
		// create answer
		$.postJSON('/answers.json', {
			survey_id: window.survey_id,
			is_preview: window.is_preview,
			email: $.trim(email_ipt.val()),
			username: username_ipt.val(),
			password: password_ipt.val(),
			introducer_id: $.util.param('i'),
			referer: window.referer
		}, function(retval) {
			if(retval.success) {
				location.href = '/a/' + retval.value + '?m=true';
				return;
			} else {
				$.util.enable(start_btn, email_ipt, username_ipt, password_ipt);
				start_btn.text('提交出错，请重试。');
				var msg = '';
				var loginString = '<a href="/signin?m=true&ref=' + encodeURIComponent(window.location.href) + '" >登录</a>';
				switch(retval.value.error_code) {
					case 'error_139': msg = '请输入邮箱再开始回答问卷。'; break;
					case 'error_138': msg = '邮箱已被注册，请先' + loginString + '后再使用此邮箱答题。'; break;
					case 'error_140': msg = (username_ipt.length > 0 ? '用户名或' : '') + '密码有误，请重新输入。'; break;
					case 'error_145': msg = (username_ipt.length > 0 ? '用户名或' : '') + '密码已被使用，请重新输入。'; break;
					case 'error_30': msg = '调查问卷不存在，可能已经被删除。'; break;
					case 'error_144': msg = '调查问卷尚未发布，请等待问卷发布之后再进行填写。'; break;
					case 'error_103': case 'error_4': msg = '对不起，您不在我们的调查范围以内。'; break;
				}
				$("#error_msg").html(msg);
				$("#error_msg").show();
			}
		});
	};
	var check_email_and_start = function(e) {
		if(email_ipt.length > 0) {
			// If need email, confirm the email
			var email = $.trim(email_ipt.val());
			if(!$.regex.isEmail(email)) {	
				$("#error_msg").text('请输入有效邮箱。');
				$("#error_msg").show();
				email_ipt.focus().select();
			} else {
				_start();
			}
		} else {
			_start();
		}
		$(e.target).blur();
	};
	start_btn.click(check_email_and_start);
});