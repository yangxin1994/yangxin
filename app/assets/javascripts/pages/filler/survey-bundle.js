//=require ui/plugins/od_enter
//=require ui/plugins/od_button_text
//=require ui/widgets/od_popup

//=require twitter/bootstrap/tooltip
//=require twitter/bootstrap/popover

jQuery(function($) {
	// start invite friends
	$('#start_invite').click(function() {
		//TODO: window.spread_url
	});

	// rewards
	$(['zhifubao', 'jifenbao', 'chongzhi']).each(function(){
		$('.' + this).popover();
	});

	// cash/lottery images
	$('.gifts-preview').hover(function() {$(this).addClass('hover');}, function() {$(this).removeClass('hover');});
	function active_gift(index) {
		$('.gifts-preview').hide();
		$('.gifts-preview:eq(' + index + ')').show();
		$('.gifts-list img').removeClass('active');
		$('.gifts-list img:eq(' + index + ')').addClass('active');
	};
	active_gift(0);
	$('.gifts-list img').mouseover(function() {
		active_gift($(this).index());
	});

	// start to fill survey
	var start_btn = $('#start_btn'), username_ipt = $('#username_ipt'), password_ipt = $('#password_ipt');
	var _start = function() {
		// set start button text
		var new_text = '正在加载问题...';
		if(username_ipt.length > 0) {
			new_text = '正在验证用户名密码...';
		} else if(password_ipt.length > 0) {
			new_text = '正在验证密码...';
		}
		start_btn.odButtonText({text: new_text});
		// disable inputs
		$.util.disable(start_btn, username_ipt, password_ipt);
		// create answer
		$.postJSON('/answers.json', {
			survey_id: window.survey_id,
			is_preview: window.is_preview,
			reward_scheme_id: window.rsi,
			introducer_id: $.util.param('i'),
			agent_task_id: $.util.param('ati'),
			channel: window.channel,
			referer: window.referer,
			username: username_ipt.val(),
			password: password_ipt.val()
		}, function(retval) {
			if(retval.success) {
				location.href = '/a/' + retval.value;
			} else {
				$.util.enable(start_btn, username_ipt, password_ipt);
				start_btn.odButtonText('destroy');
				var msg = '提交出错，请刷新页面重试。';
				switch(retval.value.error_code) {
					case 'error_140': msg = (username_ipt.length > 0 ? '用户名或' : '') + '密码有误，请重新输入。'; break;
					case 'error_145': msg = (username_ipt.length > 0 ? '用户名或' : '') + '密码已被使用，请重新输入。'; break;
					case 'error_30': msg = '调查问卷不存在，可能已经被删除。'; break;
					case 'error_144': msg = '调查问卷尚未发布，请等待问卷发布之后再进行填写。'; break;
					case 'error_103': case 'error_4': msg = '对不起，您不在我们的调查范围以内。'; break;
				}
				$.od.odPopup({content: msg});
			}
		});
	};
	start_btn.click(_start);
	password_ipt.odEnter({enter: _start});	
});