jQuery(function($) {

	// ***************
	//
	// index,show page
	//
	// *************

	//sideup
	function return_function(data, _id){
		// console.log(data);
		if(data.success == true && data.value != false){
			$("#"+_id).slideUp('slow', function(){$(this).remove();});
		}else{
			var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
			alert(info);
		}
	};

	//delete one data
	$('.delete').click(function(){
		var _id = $(this).closest('tr').attr('id');
		var retval = confirm('确定删除所选项吗？');
		if(retval){
			$.delete('/admin/review_answers/'+_id, {}, function(data){return_function(data, _id)});
		}
		return false;
	});

	//delete all data
	$('.delete-selected').click(function(){
		
		//delete all data from database	
		if($('tbody :checkbox[checked="checked"]').size() == 0){
			alert('未存在选择项');
			return false;
		}
		var retval = confirm('确定删除所选项吗？');
		if(retval){
			$('tbody :checkbox[checked="checked"]').each(function(){
				var _id = $(this).closest('tr').attr('id');
				$.delete('/admin/review_answers/'+_id, {}, function(data){return_function(data, _id)});
			});
		}
		return false;
	});

	//check all
	$('thead .check-all').change(function(){
		if(this.checked )
			$('tbody :checkbox').attr('checked','checked');
		else{
			$('tbody :checkbox').removeAttr('checked');
		}
	});

	// replace id to email
	$.each($('.user_id'), function(index,item){
		var user_id =$(item).attr('value').trim();
		var survey_id = $(item).closest('tr').attr('id');
		// console.log(survey_id);
		$.get("/admin/"+user_id+"/get_email", function(data){
			// console.log(data);
			if(data.success){
				$('.user_id[value='+user_id+']').text(data.value).removeClass('user_id');
			}
		});
		return null;
	});

	$('.audit_message_short').click(function(){
		$('#message textarea').val($(this).children('.audit_message_all').text());
		$('#message').removeClass('dn');
		return false;
	});

	$('.answers').click(function(){
		$('#new-message').addClass('dn');
		$('#message').addClass('dn');
	});

	// ***************
	//
	// show_answer page
	//
	// *************

	$('#edit-tab').click(function(){
		$('#new-message').addClass('dn');
		$('#message').addClass('dn');
	});

	$('.publish, .reject').bind('click', function(){
		// var _id=$('.opt-id').text();
		var _msg_content = $('textarea[name="message[:content]"]').val();

		if(_msg_content.trim()==""){
			alert("内容不能为空");
			return false;
		}

		if($(this).hasClass('publish')){
			$.put(window.location.pathname+'/review',
				{review_result: true, message_content: _msg_content}, function(data){
					// console.log(data);
					if(data.success){
						alert("更新成功");
						window.location.reload();
					}else{
						if(data.value.error_code == undefined){
							alert("更新失败");
							window.location.reload();
						}else{
							var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
							alert(info);
						}
					}
				});

		}else if($(this).hasClass('reject')){
			$.put(window.location.pathname+'/review',
				{review_result: false, message_content: _msg_content}, function(data){
					// console.log(data);
					if(data.success){
						alert("更新成功");
						window.location.reload();
					}else{
						if(data.value.error_code == undefined){
							alert("更新失败");
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
		$('#new-message .od-button').hide();
		$('.publish').show();
		$('textarea[name="message[:content]"]').val('您此答案通过审核了!');
		return false;
	});

	$('.rej').click(function(){
		$('.opt-id').text($(this).closest('tr').attr('id'));
		$('#new-message').removeClass('dn');
		$('#new-message .od-button').hide();
		$('.reject').show();
		$('textarea[name="message[:content]"]').val('您没有认真答题。');
		return false;
	});

});