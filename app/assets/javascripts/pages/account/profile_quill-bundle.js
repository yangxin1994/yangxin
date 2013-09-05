//=require ui/widgets/od_popup
//=require ui/plugins/od_enter

jQuery(function($) {

	var btn=$('.btnOK');

	var btnPass = $('.btnOKPass');

	btn.on('click',function(){
		$('.phone input').blur();
		$('.card input').blur();
		
		if($('.card input, .phone input').hasClass('error')){
			$.od.odPopup({content:'请确认信息的合法性，再重新提交！'});
			return false;
		}

		var full_name = $('.name input').val();
		var identity_card = $('.card input').val();
		var company = $('.company input').val();
		var phone = $('.phone input').val();
		var address = $('.address #address').val();

		btn.attr('disabled','disabled');
		btn.addClass('od-button-disable');
		$.putJSON('/profile.json', {
				full_name: full_name,
				identity_card: identity_card,
				company: company,
				phone: phone,
				address: address
			}, function(data){
				if(data.success){
					$.od.odPopup({content:'信息更新成功!'});
				}
				else{
					$.od.odPopup({content:'更新失败，您输入的信息有误！'});
				}

				btn.removeClass('od-button-disable');
				btn.removeAttr('disabled');
			})

		return false;
	});

	function savePswd() {
		$('.againPass input').blur();
		if($('.againPass input').hasClass('error')){
			$.od.odPopup({content:'您输入的重复密码有误,请重新输入！'});
			$('.againPass input').val('');
			return false;
		}

		var oldPass = $('.oldPass input').val();
		var newPass = $('.newPass input').val();
		var againPass = $('.againPass input').val();

		btnPass.attr('disabled','disabled');
		btnPass.addClass('od-button-disable');
		$.putJSON('/profile/update_password.json',{
				old_password: oldPass,
				new_password: newPass,
				new_password_confirmation: againPass
			}, function(data){
				if(data.success){
					$.od.odPopup({content:'修改密码成功!'});
					$('.oldPass input').val('');
					$('.newPass input').val('');
					$('.againPass input').val('');
				}
				else{
					var error_code=data.value.error_code;
					var pop_content="密码修改失败！";
					if(error_code=="error_10"){
						pop_content="您输入的重复密码有误,请重新输入！";
						$('.oldPass input').val('');
					}
					else if (error_code=="error_11"){
						pop_content="您输入的旧密码有误，请重新输入！";
						$('.againPass input').val('');
					}
					$.od.odPopup({content:pop_content});
				}

				btnPass.removeClass('od-button-disable');
				btnPass.removeAttr('disabled');
			})

		return false;
	};
	btnPass.click(savePswd);
	$('#againPass').odEnter({enter: savePswd});

	$('.againPass input').blur(function(){
		var newPass = $('.newPass input').val();  
		if(this.value != newPass){   
			$(this).addClass('error');
			$(this).next().html("两次输入密码不一致！");
		}else{   
			$(this).removeClass('error');
			$(this).next().html("");   
		} 
	});

	$('.card input').blur(function(){
		var idcard=$(this).val();
		if( idcard!="" && !($.regex.isIDCard(idcard)) ){   
			$(this).addClass('error');
			$(this).next().html("请输入正确的身份证号码！");   
		}else{
			$(this).removeClass('error');
			$(this).next().html("");   
		} 
	});

	$('.phone input').blur(function(){
		var mobile=$(this).val();
		if( mobile!="" && !($.regex.isMobile(mobile)) ){
			$(this).addClass('error');
			$(this).next().html("请输入正确的手机号码！");   
		}else{   
			$(this).removeClass('error');
			$(this).next().html("");   
		}  
	});  
});