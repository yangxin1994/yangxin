jQuery(function($) {

	// ***************
	//
	// list  page
	//
	// *************

	$('.publish, .reject, .pause, .close').on('click', function(){
		var _id=$('.opt-id').text();
		var _msg_content = $('textarea[name="message[:content]"]').val();

		if(_msg_content.trim()==""){
			alert("内容不能为空");
			return false;
		}

		if($(this).hasClass('publish')){
			$.put(window.location.pathname+'/'+_id+'/publish', 
				{message: {content: _msg_content}},
				function(data){
					// console.log(data);
					if(data.success){
						alert("操作成功");
						$('#'+_id).slideUp();
						
					}else{
						if(data.value.error_code == undefined){
							alert("操作失败");
						}else{
							var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
							alert(info);
						}
					}
				});

		}else if($(this).hasClass('reject')){
			$.put(window.location.pathname+'/'+_id+'/reject', 
				{message: {content: _msg_content}},
				function(data){
					// console.log(data);
					if(data.success){
						alert("操作成功");
						$('#'+_id).slideUp();
						
					}else{
						if(data.value.error_code == undefined){
							alert("操作失败");
						}else{
							var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
							alert(info);
						}
					}
				});
		}
		
		$('textarea[name="message[:content]"]').val('');
		$('#new-message').addClass('dn');
		return false;
	});

	$('.pub').click(function(){
		$('.opt-id').text($(this).closest('tr').attr('id'));
		$('#new-message').removeClass('dn');
		$('#new-message .blueBtn').hide();
		$('.publish').show();
		$('textarea[name="message[:content]"]').val('您此调查问卷通过了!');
		return false;
	});

	$('.rej').click(function(){
		$('.opt-id').text($(this).closest('tr').attr('id'));
		$('#new-message').removeClass('dn');
		$('#new-message .blueBtn').hide();
		$('.reject').show();
		$('textarea[name="message[:content]"]').val('您此调查问卷有问题!');
		return false;
	});

	$(".reviews").click(function(){
		$('#new-message').addClass('dn');
	});

	// replace id to email
	$.each($('.user_id'), function(index,item){
		var user_id =$(item).text().trim();
		var survey_id = $(item).parent().attr('id');
		$.get("/admin/"+user_id+"/get_email", function(data){
			// console.log(data);
			if(data.success){
				$('#'+survey_id+' .user_id').text(data.value).removeClass('user_id');
			}
		});
		return null;
	});
	
});