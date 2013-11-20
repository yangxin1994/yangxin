//=require jquery.SuperSlide
jQuery(function($) {
	// slide the prizes of lottery
	jQuery(".slideBox").slide({mainCell:".bd ul",autoPlay:true});
	// add spreadable dom
	// $('#sf_main .copyright').before(window.spread_dom);

	var start_btn = $('#start_btn'), username_ipt = $('#username_ipt'), password_ipt = $('#password_ipt');

	var _start = function(after_login) {
		// set start button text
		var new_text = '正在加载问题...';
		if(username_ipt.length > 0) {
			new_text = '正在验证用户名密码...';
		} else if(password_ipt.length > 0) {
			new_text = '正在验证密码...';
		}
		start_btn.text(new_text);
		// disable inputs

		$.util.disable(start_btn, username_ipt, password_ipt);
		// create answer
		$.ajax({
			url:'/answers.json',
			type:'post',
			data:{
				survey_id: window.survey_id,
				is_preview: window.is_preview,
				reward_scheme_id: window.rsi,
				channel: window.channel,
				username: username_ipt.val(),
				password: password_ipt.val(),
				introducer_id: $.util.param('i'),
				agent_task_id: $.util.param('ati'),
				referer: window.referer,				
			},
			success:function(retval){
				if(retval.success) {	
					window.location.href = window.location.protocol + "//" + window.location.host + '/a/' + retval.value + '?m=true';
					return false;
				} else {
					$.util.enable(start_btn, username_ipt, password_ipt);
					start_btn.text('提交出错，请重试。');
					var msg = '';
	
					switch(retval.value.error_code) {
						case 'error_140': msg = (username_ipt.length > 0 ? '用户名或' : '') + '密码有误，请重新输入。'; break;
						case 'error_145': msg = (username_ipt.length > 0 ? '用户名或' : '') + '密码已被使用，请重新输入。'; break;
						case 'error_30': msg = '调查问卷不存在，可能已经被删除。'; break;
						case 'error_144': msg = '调查问卷尚未发布，请等待问卷发布之后再进行填写。'; break;
						case 'error_103': case 'error_4': msg = '对不起，您不在我们的调查范围以内。'; break;
					}
					$("#error_msg").html(msg);
					$("#error_msg").show();
				}
			}
		})
	};

	start_btn.click(_start);

});