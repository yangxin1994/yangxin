jQuery(function($) {

	// **********************
	// index page
	// 
	// ***********************
	
	$("table th:first span").hide();
	$("table th:last span").hide();

	//sideup
	function return_function(data, _id){
		// console.log(data);
		if(data.value == true){
			$("#"+_id).slideUp('slow', function(){$(this).remove();});
		}else{
			var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>faq</em>:<span>"+data.value.error_faq+"</span></p>";
			alert(info);
		}
	};

	//delete one data
	$('.delete').click(function(){
		var _id = $(this).closest('tr').attr('id');
		$.delete('/admin/faqs/'+_id, {}, function(data){return_function(data, _id)});
		return false;
	});

	//delete all data
	$('.delete-selected').click(function(e){
		e.stopPropagation();
		//delete all data from database	
		if($('tbody :checkbox[checked="checked"]').size() == 0){
			alert("未存在选择项");
			return false;
		}
		var retval = confirm('确定删除所选项吗？');
		if(retval==true){
			$('tbody :checkbox[checked="checked"]').each(function(){
				var _id = $(this).closest('tr').attr('id');
				$.delete('/admin/faqs/'+_id, {}, function(data){return_function(data, _id)});
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

	// **********************
	// show/edit page
	// 
	// ***********************

	$('.btn-edit-ok').click(function() {
		var _question = $('#edit-tab [name="question"]').val();
		var _answer = $('#edit-tab [name="answer"]').val();

		$.put('/admin/faqs/'+window.location.pathname.split('/')[3],
			{question: _question, answer: _answer}, 
			function(data){
				// console.log(data);
				if(data.success){
					alert("更新成功");
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


	// **********************
	// new page
	// 
	// ***********************

	$('.btn-new-ok').click(function(){
		var _question = $('#new-tab [name="question"]').val();
		var _answer = $('#new-tab [name="answer"]').val();

		if(_question.toString().trim() == "" || _answer.toString().trim() == ""){
			alert("问题与回答都不能为空");
			return false;
		}

		$.post('/admin/faqs',
			{question: _question, answer: _answer}, 
			function(data){
				// console.log(data);
				if(data.success){
					alert("创建成功");
					window.location.replace('/admin/faqs');
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

});