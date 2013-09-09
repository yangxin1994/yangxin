jQuery(function($) {

	// ************
	// list page
	// ***************

	$("table th:first span").hide();
	$("table th:last span").hide();

	//sideup
	function return_function(data, _id){
		// console.log(data);
		if(data.value == true){
			$("#"+_id).slideUp('slow', function(){$(this).remove();});
		}else{
			var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>feedback</em>:<span>"+data.value.error_feedback+"</span></p>";
			alert(info);
		}
	};

	//delete one data
	$('.delete').click(function(){
		var _id = $(this).closest('tr').attr('id');
		$.delete('/admin/feedbacks/'+_id, {}, function(data){return_function(data, _id)});
		return false;
	});

	//delete all data
	$('.delete-selected').click(function(){
		//delete all data from database	
		if($('tbody :checkbox[checked="checked"]').size() == 0){
			alert("未存在选择项");
			return false;
		}
		var retval = confirm('确定删除所选项吗？');
		if(retval==true){
			$('tbody :checkbox[checked="checked"]').each(function(){
				var _id = $(this).closest('tr').attr('id');
				$.delete('/admin/feedbacks/'+_id, {}, function(data){return_function(data, _id)});
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
		var user_id =$(item).attr('name').trim();
		$.get("/admin/"+user_id+"/get_email", function(data){
			// console.log(data);
			if(data.success){
				$('.user_id[name='+user_id+']').text(data.value).removeClass('user_id');
			}
		});
		return null;
	});

	// ************
	// edit page
	// ***************

	// reply
	$('.btn-edit-ok').click(function(){
		var mesCon = $('textarea[name="feedback_content"]').val();
		if(mesCon.toString().trim()==""){
			alert("回复内容不能为空！");
			return false;
		}

		$.post('/admin/feedbacks/'+window.location.pathname.split('/')[3]+"/reply",
			{message_content: mesCon}, 
			function(data){
				// console.log(data);
				if(data.success){
					alert("回复成功，已向相应用户发送消息");
					window.location.reload();
				}else{
					if(data.value.error_code == undefined){
						alert("操作失败");
					}else{
						var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
						alert(info);
					}
				}
			}
		);
		return false;
	});

	//select reply
	if(window.getUrlVar().is_answer=="true")
		$('.selectReply').val("yes");
	else if(window.getUrlVar().is_answer==false)
		$('.selectReply').val("no");

	$('.selectReply').change(function(){
		var selectValue = $(':selected').val();
		if(selectValue=="yes")
			window.location.href="/admin/feedbacks?is_answer=true";
		else if(selectValue=="no")
			window.location.href="/admin/feedbacks?is_answer=false";
		else 
			window.location.href="/admin/feedbacks";
	});

});