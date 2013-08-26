jQuery(function($) {

	$('body').on('click','a.fancybox', function(data){
		$('#mobile-number').val('');
		$('#verify-code').val('');
		$('#email-input').val('');
		$('#phone-binding .cont').empty();
		$('#email-binding .cont').empty();
		$('#step2 .cont').empty().append('<p class="normal">请查收你的短信，如果<span class="timer-box">超过<span style="padding: 0px 8px;" id="timer">60</span>秒</span>未收到信息，请<a class="resend-mobile active c-blue">重新发送</a></p>');
		$('#email-binding-2 .cont').empty().append('<p>系统已向您的邮箱 <span class="c-orange"></span> 发送了一封验证邮件，请您登录邮箱，点击邮件链接完成邮箱验证。如果您超过10分钟未收到邮件，您可以重新操作或<a class="resend-email active c-blue">重新发送</a></p>');
	})
	
	// share
	$('#bindings tr').on('click', 'input[type=checkbox].share', function(){
		var ws=$(this).attr('name');
		var share=!!$(this).attr('checked');
		// console.log('......'+ws+'......')
		// console.log('...'+share+'.checked.....')
		$.putJSON(
			'/users/setting/share.json?website='+ws+'&share='+share,
			{
				website: ws,
				share: share
			}, function(data){
				// console.log(data)
				if (data.success && data.value) {
					// $.popupFancybox({cont: '操作成功', success: true})
				}else {
					$.popupFancybox()
				}
			}
		)
	})

	// subscribe
	$('#bindings tr').on('click', 'input[type=checkbox].subscribe', function(){
		var _type=$(this).attr('name');
		var is_subscribe=!!$(this).attr('checked');
		// console.log('......'+ws+'......')
		// console.log('...'+share+'.checked.....')
		$.putJSON(
			'/users/setting/subscribe.json?type='+_type+'&sub='+is_subscribe,
			{
				type: _type,
				subscribe: is_subscribe
			}, function(data){
				// console.log(data)
				if (data.success && data.value) {
					// $.popupFancybox({cont: '操作成功', success: true})
				}else {
					$.popupFancybox()
				}
			}
		)
	})

	// timer
	var timer;
	function myTimer() {
		var sec = 60
		clearInterval(timer);
		timer = setInterval(function() { 
			$('#timer').text(sec--);
			if (sec == -1) {
				clearInterval(timer);
				$('#step2 .cont p .timer-box').hide();
				$('#step2 .cont .resend-mobile').addClass('active').removeClass('c-lgray');
			} 
		}, 1000);
	}

	// bind mobile
	$('.edit-phone').on('click', 'a.btn.btn-send_mobile:not(.disabled)', function(){

		if(!/^1[3|4|5|8][0-9]\d{8}$/.test( $.trim($('#mobile-number').val())) ) {
			$('#mobile-number').addClass('error');
			$('#phone-binding .cont').append('<p>请填写正确的手机号码</p>')
			return false;
		}
		var _this = $(this);
		_this.addClass('disabled').text("提交中");
		$.putJSON(
			'/users/setting/change_mobile',
			{
				m: $.trim($('#mobile-number').val())
			}, function(data){
				// console.log(data)
				_this.removeClass('disabled').text("下一步");
				if (data.success && data.value) {
					$.fancybox($('#step2'), {
						beforeShow: function(){
							$(".fancybox-skin").css({"backgroundColor":"#fff"});
						}
					});
					$('#verify-code').focus();
					$('#step2 .cont .resend-mobile').removeClass('active').addClass('c-lgray');
					myTimer();
				}else {
					$.popupFancybox();
				}
			}
		)
	})

	// enter keypress in phone input
	$('.edit-phone').on('keypress'," input[type=text]#mobile-number", function(event){
		if (event.which == 13){
			$('.edit-phone a.btn.btn-send_mobile').click();
		}
	})

	// mobile number blur action
	$('#mobile-number').blur(function(){
		if(!/^1[3|4|5|8][0-9]\d{8}$/.test( $.trim($('#mobile-number').val())) ) {
			$('#mobile-number').addClass('error')
		}else{
			$('#mobile-number').removeClass('error')
		}
	})

	// re-send mobile 
	$('.cont').on('click', 'a.resend-mobile.active', function(){
		$('#step2 .cont p.c-red').remove();
		$('#step2 .cont .resend-mobile.active').removeClass('active').addClass('c-lgray');

		$.putJSON(
			'/users/setting/change_mobile',
			{
				m: $.trim($('#mobile-number').val())
			}, function(data){
				// console.log(data)
				if (data.success && data.value) {
					$('#step2 .cont p.normal .timer-box').show();
					myTimer();
				}else {
					$('#step2 .cont .resend-mobile').addClass('active').removeClass('c-lgray');
				}
			}
		)
	})

	// checking the mobile verify code
	$('.edit-phone').on('click', 'a.btn.btn-verify_code:not(.disabled)', function(){
		var _this = $(this);
		_this.addClass('disabled').text("提交中");

		$.putJSON(
			'/users/setting/check_mobile_verify_code',
			{
				m: $.trim($('#mobile-number').val()),
				code: $.trim($('#verify-code').val())
			}, function(data){
				// console.log(data)
				_this.removeClass('disabled').text("提交");
				if (data.success && data.value) {
					$.fancybox($('#step3'), {
						beforeShow: function(){
							$(".fancybox-skin").css({"backgroundColor":"#fff"});
						}
					});
				}else {
					if (data.value.error_code=="error_02") {
						$('#step2 .cont p.c-red').remove();
						$('#step2 .cont').append('<p class="c-red">验证码有误，请重新填写！</p>')
					}else if (data.value.error_code=="error_5"){
						$('#step2 .cont p.c-red').remove();
						$('#step2 .cont').remove('p.c-red').append('<p class="c-red">验证码已经过期！</p>')
					}
					$('#verify-code').addClass('error')
				}
			}
		)
	});

	// enter keypress in code input
	$('.edit-phone').on('keypress',"input[type=text]#verify-code", function(event){
		if (event.which == 13){
			$('.edit-phone a.btn.btn-verify_code').click();
		}
	})

	// ***************** email  ********

	$('#email-input').blur(function(){
		if(!/^([a-zA-Z0-9]+[_|\_|\.]?)*[a-zA-Z0-9]+@([a-zA-Z0-9]+[_|\_|\.]?)*[a-zA-Z0-9]+\.[a-zA-Z]{2,3}$/.test( $.trim($('#email-input').val())) ) {
			$('#email-input').addClass('error')
		}else{
			$('#email-input').removeClass('error')
		}
	})

	// send from email
	$('.edit-email').on('click', 'a.btn.btn-send_email', function(){
		if(!/^([a-zA-Z0-9]+[_|\_|\.]?)*[a-zA-Z0-9]+@([a-zA-Z0-9]+[_|\_|\.]?)*[a-zA-Z0-9]+\.[a-zA-Z]{2,3}$/.test($.trim($('#email-input').val())) ) {
			$('#email-input').addClass('error')
			$('#email-binding .cont').empty().append('<p>非正确的邮箱格式，请输入正确的邮箱</p>')
			return false;
		}
		var _this = $(this);
		_this.addClass('disabled').text("提交中");
		$.putJSON(
			'/users/setting/change_email',
			{
				email: $.trim($('#email-input').val())
			}, function(data){
				// console.log(data)
				_this.removeClass('disabled').text("下一步");
				if (data.success && data.value) {
					$('#email-binding-2 .cont .c-orange').text($.trim($('#email-input').val()));
					$('a.btn-link-email').attr('href', 'http://mail.'+$.trim($('#email-input').val()).split('@')[1])
					$.fancybox($('#email-binding-2'), {
						beforeShow: function(){
							$(".fancybox-skin").css({"backgroundColor":"#fff"});
						}
					});
				}else {
					if (data.value.error_code=="error___3") {
						$('#email-binding .cont').empty().append('<p>此邮箱已经被使用，请选择其它邮箱</p>')
					}
					$('#verify-code').addClass('error')
				}
			}
		)
	})

	// enter keypress in code input
	$('.edit-email').on('keypress',"input#email-input", function(event){
		if (event.which == 13){
			$('.edit-email a.btn.btn-send_email').click();
		}
	})

	$('.cont').on('click', 'a.resend-email.active', function(){
		$("#send-email-success-info").hide();
		$('#email-binding-2 .cont .resend-email').addClass('c-green').removeClass('active').text('发送中...');

		$.putJSON(
			'/users/setting/change_email',
			{
				email: $.trim($('#email-input').val())
			}, function(data){
				// console.log(data)
				if (data.success && data.value) {
					$("#send-email-success-info").show();
					$('#email-binding-2 .cont .resend-email').animate({opacity: 1}, 2000, function(){
						$('#email-binding-2 .cont .resend-email').addClass('active').text('重新发送').removeClass('c-green');
					})
				}else {
					$('#email-binding-2 .cont .resend-email').addClass('active').text('，发送失败，请重新发送').removeClass('c-green')
				}
			}
		)
	})

	$('.actions').on('click', 'a.btn.btn-over', function(){
		window.location.replace('/users/setting/bindings');
	})
});