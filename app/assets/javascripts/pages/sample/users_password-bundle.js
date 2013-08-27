jQuery(function($) {  
	$('.actions').on("click", ".btn.btn-submit",function(){
		var opwd= $.trim($('#opwd').val());
		var npwd = $.trim($('#npwd').val());
		var cpwd = $.trim($('#cpwd').val());

		// checked first time
		if ($('.error:not(#cpwd)').length > 0){ return false;}
		$('input[type=password]').removeClass('error');
		$('.alert-error').addClass('alert-hide');

		// verified
		if( opwd.length == 0 ) {
				$('#opwd').addClass('error');
				$('.alert-opwd').removeClass('alert-hide');
		}
		
		if( npwd.length == 0 ) {
				$('#npwd').addClass('error');
				$('.alert-npwd').removeClass('alert-hide');
		}else{
			if (npwd == opwd){
				$('#npwd').addClass('error');
				$('.alert-npwd2').removeClass('alert-hide');
			}
		}

		if( cpwd.length == 0 ) {
				$('#cpwd').addClass('error');
				$('.alert-cpwd').removeClass('alert-hide');
		}
		else {
			if( cpwd != npwd ) {
				$('#cpwd').addClass('error');
				$('.alert-cpwd2').removeClass('alert-hide');
			}  
		}

		console.log('.......'+$('.error').length+'......')

		// checked
		if ($('.error').length > 0) { return false; };

		var _this = $(this);
		_this.addClass('disabled').val("提交中...");
		
		$.putJSON('/users/setting/password',
			{
				old_password: opwd,
				new_password: npwd
			},
			function(data){
				// console.log(data);
				_this.removeClass('disabled').val("确认提交");
				_this.focus();
				if (data.success && data.value){
					$.popupFancybox({success: true, cont: "登录密码修改成功！"});
					$('input[type=password]').val('');
				}else {
					if (data.value.error_code == 'error_11') {
						$('#opwd').addClass('error');
						$('.alert-opwd2').removeClass('alert-hide');
						// $.popupFancybox({cont: "操作失败，请保证原密码正确！"});            
					}else{
						$.fancybox($('#popup-fail'));
					}
				}
		});
	});

	// enter keypress in code input
	$('#password').on('keypress',"input[type=password]", function(event){
		if (event.which == 13){
			$('#password .actions .btn.btn-submit').click();
		}
	})

	$('#opwd').blur(function(){
		// $('#opwd').addClass('error');
		// $('.alert-opwd2').addClass('alert-hide');
		if( $.trim($(this).val()).length == 0 ) {
			$(this).addClass('error');
			$('.alert-'+$(this).attr('id')).removeClass('alert-hide');
		}else{
			$(this).removeClass('error');
			$('.alert-'+$(this).attr('id')).addClass('alert-hide');
		}
	});

	$('#npwd').blur(function(){
		var opwd= $.trim($('#opwd').val());
		var npwd = $.trim($('#npwd').val());
		var cpwd = $.trim($('#cpwd').val());
		
		$('.alert-npwd, .alert-npwd2').addClass('alert-hide');
		// $('#cpwd').removeClass('error');
		
		if( npwd.length == 0 ) {
				$('#npwd').addClass('error');
				$('.alert-npwd').removeClass('alert-hide');
		}
		else {
			$('#npwd').removeClass('error');
			$('.alert-npwd').addClass('alert-hide');

			if (npwd != opwd){
				$('.alert-npwd2').addClass('alert-hide');
			}

			if( $.trim(cpwd) != "" && $.trim(cpwd) != $.trim(npwd) ) {
					$('#cpwd').addClass('error');
					$('.alert-cpwd2').removeClass('alert-hide');
			} else {
					$('.alert-cpwd2').addClass('alert-hide');
			}
		}
	});

	$('#cpwd').blur(function(){
		var npwd = $.trim($('#npwd').val());
		var cpwd = $.trim($('#cpwd').val());
		$('.alert-cpwd, .alert-cpwd2').addClass('alert-hide');
		
		if( cpwd != npwd ) {
			$('#cpwd').addClass('error');
			$('.alert-cpwd2').removeClass('alert-hide');
		}else{
			$('#cpwd').removeClass('error');
		}
	});
});