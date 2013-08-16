jQuery(function($) {

	// *************
	//  Index page
	// **************
	// .allocate_user operate
	// window.replaceIdToText=function(question_id){
	// 	// console.log('user_id:::'+user_id.trim());
	// 	$.get("/admin/template_questions/"+question_id+"/get_text", function(data){
	// 		if(data.success){
	// 			$($('tr#'+question_id+' td')[1]).children('a').text(data.value);
	// 		}
	// 	});
	// 	return null;
	// }

	// $.each($('tr.question_item'), function(index,item){
	// 	window.replaceIdToText($(item).attr('id'));
	// });

	// load template question from question type
	function loadTemplateQuestion(question_type){
		$('.add_question_to_survey').attr('disabled','disabled');
		$.get('/admin/template_questions.json?per_page=100&question_type='+question_type,function(data){
			// console.log(data);
			if(data.success){
				$('select.template_question').empty();
				$.each(data.value.data, function(index, item){
					var $option = $('<option value=""></option>');
					$option.val(item._id).text(item.content.text);
					$('select.template_question').append($option);
				});
				$('.add_question_to_survey').removeAttr('disabled');
			}else{
				if(data.value.error_code == undefined){
					alert("加载失败");
				}else{
					var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
					alert(info);
				}
				$('.add_question_to_survey').removeAttr('disabled');
			}
		});
	}

	// load choice template question
	loadTemplateQuestion(0)

	// load template question from question_type
	$('select.question_type').change(function(){
		loadTemplateQuestion($(this).val());
	});


	//add_question_to_survey
	$('.add_question_to_survey').click(function(){
		var s_id = $('.survey_id').attr('id');
		var q_id = $('select.template_question').val();

		if (s_id == undefined){
			// No exist volunteer survey! created!
			$('.blueBtn').attr('disabled', 'disabled')
			$.post('/admin/volunteer_surveys/add_template_question.json',
				{question_id: q_id},function(data){
					$('.blueBtn').removeAttr('disabled')
					// console.log(data);
					if(data.success==true && data.value==true){
						alert("成功");
						window.location.reload();
					}else{
						alert("失败");
					}
			});
		}else{
			// Exist volunteer survey! add template question!
			if(q_id==null || q_id==undefined){
				alert("未能成功选择模板题！");
				return false;
			}

			$('.blueBtn').attr('disabled', 'disabled')
			$.post('/admin/volunteer_surveys/add_template_question.json',
				{question_id: q_id, id: s_id},function(data){
					$('.blueBtn').removeAttr('disabled')
					// console.log(data);
					if(data.success==true && data.value==true){
						alert("成功");
						window.location.reload();
					}else{
						alert("失败");
					}
			});
		}
		
		return false;
	});

	// delete
	$('.delete').click(function(){
		var q_id = $(this).closest('tr').attr('id');
		var s_id = $('.survey_id').attr('id');
		$.delete('/admin/volunteer_surveys/del_question.json',
			{question_id: q_id, id: s_id},function(data){
				// console.log(data);
				if(data.success==true && data.value==true){
					alert("成功");
					// window.location.reload();
					$('tr#'+q_id).remove();
				}else{
					alert("失败");
				}
		});
		return false;
	});
});