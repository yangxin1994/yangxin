//=require ui/widgets/od_popup
//=require ui/plugins/od_enter

jQuery(function($) {
	var btn=$('#save-info');

	var btnPass = $('#save-password');

	btn.on('click',function(){
		$('#idNmber').blur();
		$('#phoneNumber').blur();
		if($('#idNmber, #phoneNumber').hasClass('error')){
			$.od.odPopup({content:'请确认信息的合法性，再重新提交!',popupStyle:"quillme"});
			return false;
		}

		var full_name = $('#name').val();
		var identity_card = $('#idNmber').val();
		var phone = $('#phoneNumber').val();
		var address = $('#address').val();

		btn.attr('disabled','disabled');
		btn.addClass('od-button-disable');
		$.putJSON('/profile.json', {
				full_name: full_name,
				identity_card: identity_card,
				phone: phone,
				address: address
			}, function(data){
				if(data.success){
					$.od.odPopup({content:'信息更新成功!',popupStyle:"quillme"});
				}
				else{
					$.od.odPopup({content:'更新失败，您输入的信息有误！',popupStyle:"quillme"});
				}

				btn.removeClass('od-button-disable');
				btn.removeAttr('disabled');
			})

		return false;
	});

	function updatePassword() {
		$('#againPassword').blur();
		if($('#againPassword').hasClass('error')){
			$.od.odPopup({content:'您输入的重复密码有误,请重新输入！',popupStyle:"quillme"});
			$('#againPassword').val('');
			return false;
		}

		var oldPass = $('#oldPassword').val();
		var newPass = $('#newPassword').val();
		var againPass = $('#againPassword').val();

		btnPass.attr('disabled','disabled');
		btnPass.addClass('od-button-disable');
		$.putJSON('/profile/update_password.json',
			{
				old_password: oldPass,
				new_password: newPass,
				new_password_confirmation: againPass
			}, function(data){
				if(data.success){
					$.od.odPopup({content:'修改密码成功!',popupStyle:"quillme"});
					$('#oldPassword').val('');
					$('#newPassword').val('');
					$('#againPassword').val('');
				}
				else{
					var error_code=data.value.error_code;
					var pop_content="密码修改失败！";
					if(error_code=="error_10"){
						pop_content="您输入的重复密码有误,请重新输入！";
						$('#oldPassword').val('');
					}
					else if (error_code=="error_11"){
						pop_content="您输入的旧密码有误，请重新输入！";
						$('#oldPassword').val('');
					}
					$.od.odPopup({content:pop_content,popupStyle:"quillme"});
				}

				btnPass.removeClass('od-button-disable');
				btnPass.removeAttr('disabled');
			})

		return false;
	}
	btnPass.click(updatePassword);
	$('#againPassword').odEnter({enter: updatePassword});

	$('#againPassword').blur(function(){
		var newPass = $('#newPassword').val();  
		if(this.value != newPass){   
			$(this).addClass('error');
			if($(".pw_error").length<=0){
				var div=$('<div />').addClass('alertDiv pw_error').html("两次输入密码不一致！");
				$(this).parent().append(div);
			}
		}else{   
			$(this).removeClass('error');
			$(this).next().remove();   
		} 
	});

	$('#idNmber').blur(function(){
		var idcard=$(this).val();
		if( idcard!="" && !($.regex.isIDCard(idcard)) ){
			$(this).addClass('error');
			if($(".idcard_error").length<=0){
				var div=$('<div />').addClass('alertDiv idcard_error').html("请输入正确的身份证号码!");
				$(this).parent().append(div);
			}			
		}else{   
			$(this).removeClass('error');
			$(this).next().remove();   
		} 
	});

	$('#phoneNumber').blur(function(){
		var mobile=$(this).val();
		if( mobile!="" && !($.regex.isMobile(mobile)) ){
			$(this).addClass('error');
			if($(".phone_error").length<=0){
				var div=$('<div />').addClass('alertDiv phone_error').html("请输入正确的手机号码!");
				$(this).parent().append(div);
			}			
		}else{
			$(this).removeClass('error');
			$(this).next().remove();   
		}
	});
});