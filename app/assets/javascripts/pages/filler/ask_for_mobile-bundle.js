$(function(){
	var mobile_ipt = $('#username_ipt');
	send_ajax = function(mob,aid,btn){
		$.postJSON('/answers/' + aid + '/submit_mobile.json', {
			mobile: mob
		}, function(retval) {
			if(retval.success){
        var aid = retval.value;
				window.location.href = '/a/' + aid;
			}else{
				if('error__10' == retval.value.error_code){
					btn.addClass('error').text('该手机已经参与过答题');
				}
			}
		});
	}



	mobile_ipt.focus(function(){
		$(this).removeClass('error');
		$('#start_btn').removeClass('error').text('提交');
	})

	$('#start_btn').click(function(){
		var mobile = mobile_ipt.val();
		if($.regex.isMobile(mobile)){
			mobile_ipt.removeClass('error');
			send_ajax(mobile,aid,$(this));
		}else{
			mobile_ipt.addClass('error');
		}
		
	})
})
