//=require ui/plugins/od_enter
//=require ui/plugins/od_button_text
//=require ui/widgets/od_popup
//=require ui/widgets/od_share
//=require jquery.qrcode

//=require twitter/bootstrap/tooltip
//=require twitter/bootstrap/popover

jQuery(function($) {
	// wechart spread
	// start invite friends
	$('#start_invite').click(function() {
		$.od.odShare({
			point: parseInt($('#spread_point').text()),
			survey_title: $('#survey_title').text(),
			scheme_id: window.rsi,
			images: ""	//TODO: images for lottery
		});
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
		var new_text = window.survey_lang == 'en' ? 'Loading...' : '正在加载问题...';
		if(username_ipt.length > 0) {
			new_text = window.survey_lang == 'en' ? 'Checking...' : '正在验证用户名密码...';
		} else if(password_ipt.length > 0) {
			new_text = window.survey_lang == 'en' ? 'Checking...' : '正在验证密码...';
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
			agent_user_id: $.util.param('agent_user_id'),
			task_id: $.util.param('task_id'),
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
				var msg = window.survey_lang == 'en' ? 'Submit error. Please refresh page.' : '提交出错，请刷新页面重试。';
        if(window.survey_lang == 'en') {
          switch(retval.value.error_code) {
            case 'error_140': msg = (username_ipt.length > 0 ? 'Username or ' : '') + 'password error.'; break;
            case 'error_145': msg = (username_ipt.length > 0 ? 'Username or ' : '') + 'password has been used.'; break;
            case 'error_30': msg = 'Survey does not exist'; break;
            case 'error_144': msg = 'Survey is closed'; break;
            case 'error_103': case 'error_4': msg = 'Sorry. You are not our survey candidate.'; break;
          }
        } else {
          switch(retval.value.error_code) {
            case 'error_140': msg = (username_ipt.length > 0 ? '用户名或' : '') + '密码有误，请重新输入。'; break;
            case 'error_145': msg = (username_ipt.length > 0 ? '用户名或' : '') + '密码已被使用，请重新输入。'; break;
            case 'error_30': msg = '调查问卷不存在，可能已经被删除。'; break;
            case 'error_144': msg = '调查问卷尚未发布，请等待问卷发布之后再进行填写。'; break;
            case 'error_103': case 'error_4': msg = '对不起，您不在我们的调查范围以内。'; break;
          }
        }
				$.od.odPopup({content: msg});
			}
		});
	};
	start_btn.click(_start);
	password_ipt.odEnter({enter: _start});	
});
