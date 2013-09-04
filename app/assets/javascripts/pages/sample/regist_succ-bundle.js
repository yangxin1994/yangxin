//=require base64
//=require utility/ajax
$(function(){

	var uri = location.href;
	var params = uri.substring(uri.indexOf('?')+3,uri.length);
	var email  = Base64.decode(params)

		$('a.re_mail').click(function(){
			re_mail($(this),$(this).attr('href'),params)
		})

		$('#y_mail').focus(function(){
			$(this).removeClass('error')
		})

		$('button.binding_now').click(function(){
			var email = $('#y_mail').val()
			if (email.length < 1 || !$.regex.isEmail(email)){
				$('#y_mail').addClass('error')
			}else{
				$.putJSON('/users/setting/change_email',{email: email.trim()}, function(data){
						if (data.success) {
							$('button.binding_now').next('.re_notice').find('span').css('background-image','url("/assets/od-quillme/success.png")')
							$('button.binding_now').next('.re_notice').find('font').text('验证成功')
							$('button.binding_now').next('.re_notice').show()
						}else {
							$('button.binding_now').next('.re_notice').find('span').css('background-image','url("/assets/od-quillme/faild.png")')
							$('button.binding_now').next('.re_notice').find('font').text('此邮箱已经被使用')
							$('button.binding_now').next('.re_notice').show()
						}
					})  					
			}
		})


		function re_mail(obj,link,params){
			$.getJSON('/account/re_mail.json',{k:params},function(retval){
				if(retval.success){
					$('.re_notice').show();
				}else{
					console.log(retval)
				}
			})    	
		}

})