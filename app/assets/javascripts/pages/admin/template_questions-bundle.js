jQuery(function($) {

	// ***************
	//
	// list  page
	//
	// *************

	//sideup
	function return_function(data, _id){
		// console.log(data);
		if(data.success == true && data.value != false){
			$("#"+_id).slideUp('slow', function(){$(this).remove();});
			// window.location.reload();
		}else{
			var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
			alert(info);
		}
	};

	//delete one data
	$('.delete').click(function(){
		var _id = $(this).closest('tr').attr('id');
		$.delete('/admin/template_questions/'+_id, {}, function(data){return_function(data, _id)});
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
				$.delete('/admin/template_questions/'+_id, {}, function(data){return_function(data, _id)});
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

	//change select type
	$('select[name=template_question_types]').change(function(){
		if(parseInt($(this).val()) < 100){
			window.location.replace("/admin/template_questions?question_type="+$(this).val().toString());
		}else{
			window.location.replace("/admin/template_questions");
		}
		
	});

	// //***************
	// //
	// //  show page
	// //
	// //***********************

	//blur 
	$('[name="template_question[:item_num_per_group]"], [name="template_question[:precision]"], [name="template_question[:format]"], [name="template_question[:sum]"], [name="template_question[:min]"], [name="template_question[:max]"], [name="template_question[:min_choice]"], [name="template_question[:max_choice]"], [name="template_question[:option_type]"], [name="template_question[:row_num_per_group]"]').blur(function(){
		if(parseInt(this.value).toString() == "NaN")
		{
			$(this).parent().children('.alertSpan').text("请输入正确的数字");
			$(this).addClass('error');
		}else{
			$(this).parent().children('.alertSpan').text("");
			$(this).removeClass('error');
		}
	});

	// new choice
	$('.new-choice').click(function(e){
		var $item=$('#choice-item').clone(true);
		$item.removeClass('dn')
			.addClass('choice')
			.attr('id','choice-'+$.util.uid());

		$item.appendTo('.group-1 .choices');
		return false;
	});

	// new row
	$('.new-row').click(function(e){
		var $item=$('#choice-item').clone(true);
		$item.removeClass('dn')
			.addClass('choice')
			.attr('id','choice-'+$.util.uid());

		$item.appendTo('.group-2 .choices');
		return false;
	});

	// new label
	$('.new-label').click(function(e){
		var $item=$('#choice-item').clone(true);
		$item.removeClass('dn')
			.addClass('choice')
			.removeAttr('id');

		$item.children('.redBtn')
			.removeClass('.btn-choice-delete')
			.addClass('.btn-label-delete');

		$item.appendTo('.group-2 .choices');
		return false;
	});

	// del choice or row
	$('.btn-choice-delete').click(function(){
		var _id = $(this).parent().attr('id');
		$('.choices #'+_id).remove();
		$('.answer-choices #'+_id).remove();
		return false;
	});

	// del label
	$('.btn-label-delete').click(function(){
		$(this).parent().remove();
		return false;
	});

	function updateQuestion(_content, _attribute_name, _issue){
		$('.blueBtn').attr('disabled','disabled');
		$.put('/admin/template_questions/'+window.location.pathname.split('/')[3],
			{
				content: _content,
				attribute_name: _attribute_name,
				issue: _issue
			}, 
			function(data){
				$('.blueBtn').removeAttr('disabled');
				if(data.success){
					alert("更新成功");
				}else{
					if(data.value.error_code == undefined){
						alert("更新失败");
					}else{
						var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
						alert(info);
					}
				}

				
			}
		);
	}

	$('.btn-edit-ok').click(function() {
		var _has_error=false;
		$.each($('#edit-tab [name^="template_question"]'), function(index, value){
			if($(value).hasClass('error')){
				_has_error = true;
				return false;
			}
		});
		if(_has_error){
			alert("更新信息存在错误，请修正");
			return false;
		}
		
		var _text=$('#edit-tab [name="template_question[:content]"]').val();
		var _attribute_name=$('#edit-tab [name="template_question[:attribute_name]"]').val();

		// diff issue
		switch(parseInt($($('.type-div')[0]).attr('id').split('_')[1])){
			//diff type, diff data struct
			case 0:
				var _is_list_style=$('#type_0 [name="template_question[:is_list_style]"]').attr('checked')=="checked";
				var _is_rand=$('#type_0 [name="template_question[:is_rand]"]').attr('checked')=="checked";
				var _option_type = parseInt($(' #type_0 [name="template_question[:option_type]"]').val()%7);
				var _min_choice = parseInt($(' #type_0 [name="template_question[:min_choice]"]').val());
				var _max_choice=parseInt($('#type_0 [name="template_question[:max_choice]"]').val());
				var _items=new Array($('#type_0 .group-1 .choices .choice').length);
				$.each($('#type_0 .group-1 .choices .choice .choice-text'), function(index, obj){
					var _item = {
						content: {
							text: $(obj).val(),
							video: "",
							image: "",
							audio: ""
						}, 
						id: $(obj).parent().attr('id').split('-')[1]
					}
					_items[index] = _item;
				});
				if(_min_choice>_max_choice || _max_choice>_items.length || _items.length == 0){
					alert("更新信息存在逻辑错误，请修正");
					return false;
				}
				updateQuestion(_text, _attribute_name, {
					is_list_style: _is_list_style,
					is_rand: _is_rand,
					option_type: _option_type,
					min_choice: _min_choice, 
					max_choice: _max_choice, 
					items: _items})
				break;
			case 1:
				// same as choice
				var _is_list_style=$('#type_1 [name="template_question[:is_list_style]"]').attr('checked')=="checked";
				var _is_rand=$('#type_1 [name="template_question[:is_rand]"]').attr('checked')=="checked";
				var _option_type = parseInt($('#type_1 [name="template_question[:option_type]"]').val()%7);
				var _min_choice = parseInt($('#type_1 [name="template_question[:min_choice]"]').val());
				var _max_choice=parseInt($('#type_1 [name="template_question[:max_choice]"]').val());
				var _items=new Array($('#type_1 .group-1 .choices .choice').length);
				$.each($('#type_1 .group-1 .choices .choice .choice-text'), function(index, obj){
					var _item = {
						content: {
							text: $(obj).val(),
							video: "",
							image: "",
							audio: ""
						}, 
						id: $(obj).parent().attr('id').split('-')[1]
					}
					_items[index] = _item;
				});

				// diff with choice
				var _row_num_per_group = parseInt($('#type_1 [name="template_question[:row_num_per_group]"]').val());
				var _show_style =parseInt($('#type_1 input[name="template_question[:show_style]"]:checked').val());
				var _is_row_rand=$('#type_1 [name="template_question[:is_row_rand]"]').attr('checked')=="checked";
				var _rows=new Array($('#type_1 .group-2 .choices .choice').length);
				$.each($('#type_1 .group-2 .choices .choice .choice-text'), function(index, obj){
					var _row = {
						content: {
							text: $(obj).val(),
							video: "",
							image: "",
							audio: ""
						}, 
						id: $(obj).parent().attr('id').split('-')[1]
					}
					_rows[index] = _row;
				});

				if(_items.length == 0 || _rows.length==0 || _min_choice>_max_choice || _max_choice>_items.length){
					alert("更新信息存在逻辑错误，请修正");
					return false;
				}

				updateQuestion(_text, _attribute_name, {
					is_list_style: _is_list_style,
					is_rand: _is_rand,
					option_type: _option_type,
					min_choice: _min_choice, 
					max_choice: _max_choice, 
					items: _items,
					row_num_per_group: _row_num_per_group,
					show_style: _show_style,
					is_row_rand: _is_row_rand,
					rows: _rows
				})
				break;
			case 2:
				var _min_length = parseInt($('#type_2 [name="template_question[:min_length]"]').val());
				var _max_length=parseInt($('#type_2 [name="template_question[:max_length]"]').val());
				var _has_multiple_line=$('#type_2 [name="template_question[:has_multiple_line]"]').attr('checked')=="checked";
				var _size =parseInt($('#type_2 input[name="template_question[:size]"]:checked').val());
				updateQuestion(_text, _attribute_name, {
					min_length: _min_length,
					max_length: _max_length,
					has_multiple_line: _has_multiple_line,
					size: _size
				})
				break;
			case 3:
				var _precision = parseInt($('#type_3 [name="template_question[:precision]"]').val());
				var _min_value = parseInt($('#type_3 [name="template_question[:min_value]"]').val());
				var _max_value=parseInt($('#type_3 [name="template_question[:max_value]"]').val());
				var _unit=$('#type_3 [name="template_question[:unit]"]').val();
				var _unit_location =parseInt($('#type_3 input[name="template_question[:unit_location]"]:checked').val());
				updateQuestion(_text, _attribute_name, {
					precision: _precision,
					min_value: _min_value,
					max_value: _max_value,
					unit: _unit,
					unit_location: _unit_location
				})
				break;
			case 4:
				// no issue
				updateQuestion(_text, _attribute_name, {})
				break;
			case 5:
				// no issue
				updateQuestion(_text, _attribute_name, {})
				break;
			case 6:
				var _phone_type =parseInt($('#type_6 input[name="template_question[:phone_type]"]:checked').val());
				updateQuestion(_text, _attribute_name, {
					phone_type: _phone_type
				})
				break;
			case 7:
				var _format =parseInt($('#type_7 input[name="template_question[:format]"]:checked').val());				
				var _min_time = parseInt($('#type_7 [name="template_question[:min_time]"]').val());
				var _max_time=parseInt($('#type_7 [name="template_question[:max_time]"]').val());
				updateQuestion(_text, _attribute_name, {
					format: _format,
					min_time: _min_time,
					max_time: _max_time
				})
				break;
			case 8: 
				var _has_postcode=$('#type_8 [name="template_question[:has_postcode]"]').attr('checked')=="checked";
				var _format = parseInt($('#type_8 [name="template_question[:format]"]').val()%16);
				updateQuestion(_text, _attribute_name, {
					format: _format,
					has_postcode: _has_postcode
				})
				break;
			case 9:
				alert("未实现此类型功能");
				break;
			case 10:
				alert("未实现此类型功能");
				break;
			case 11:
				var _is_rand=$('#type_11 [name="template_question[:is_rand]"]').attr('checked')=="checked";
				var _show_style =parseInt($('#type_11 input[name="template_question[:show_style]"]:checked').val());
				var _sum = parseInt($(' #type_11 [name="template_question[:sum]"]').val());
				var _items=new Array($('#type_11 .group-1 .choices .choice').length);
				$.each($('#type_11 .group-1 .choices .choice .choice-text'), function(index, obj){
					var _item = {
						content: {
							text: $(obj).val(),
							video: "",
							image: "",
							audio: ""
						}, 
						id: $(obj).parent().attr('id').split('-')[1]
					}
					_items[index] = _item;
				});
				if(_items.length == 0){
					alert("更新信息存在逻辑错误，请修正");
					return false;
				}
				updateQuestion(_text, _attribute_name, {
					is_rand: _is_rand,
					show_style: _show_style,
					sum: _sum,
					items: _items})
				break;
			case 12:
				var _is_rand=$('#type_12 [name="template_question[:is_rand]"]').attr('checked')=="checked";
				var _min = parseInt($(' #type_12 [name="template_question[:min]"]').val());
				var _max=parseInt($('#type_12 [name="template_question[:max]"]').val());
				var _items=new Array($('#type_12 .group-1 .choices .choice').length);
				$.each($('#type_12 .group-1 .choices .choice .choice-text'), function(index, obj){
					var _item = {
						content: {
							text: $(obj).val(),
							video: "",
							image: "",
							audio: ""
						}, 
						id: $(obj).parent().attr('id').split('-')[1]
					}
					_items[index] = _item;
				});
				if(_min_choice>_max_choice || _max_choice>_items.length || _items.length == 0){
					alert("更新信息存在逻辑错误，请修正");
					return false;
				}
				updateQuestion(_text, _attribute_name, {
					is_rand: _is_rand,
					min: _min,
					max: _max, 
					items: _items
				})
				break;
			case 13:
				alert("未实现此类型功能");
				break;
			case 14:
				// no issue
				updateQuestion(_text, _attribute_name, {})
				break;
			case 15:
				alert("未实现此类型功能");
				break;
			case 16:
				alert("未实现此类型功能");
				break;
			case 17:
				var _is_rand=$('#type_17 [name="template_question[:is_rand]"]').attr('checked')=="checked";
				var _show_style =parseInt($('#type_17 input[name="template_question[:show_style]"]:checked').val());
				var _item_num_per_group = parseInt($('#type_17 [name="template_question[:item_num_per_group]"]').val());
				var _show_unknown=$('#type_17 [name="template_question[:show_unknown]"]').attr('checked')=="checked";

				var _items=new Array($('#type_17 .group-1 .choices .choice').length);
				$.each($('#type_17 .group-1 .choices .choice .choice-text'), function(index, obj){
					var _item = {
						content: {
							text: $(obj).val(),
							video: "",
							image: "",
							audio: ""
						}, 
						id: $(obj).parent().attr('id').split('-')[1]
					}
					_items[index] = _item;
				});
				
				var _labels=new Array($('#type_17 .group-2 .choices .choice').length);
				$.each($('#type_17 .group-2 .choices .choice .choice-text'), function(index, obj){
					var _label = $(obj).val();
					_labels[index] = _label;
				});

				if(_items.length == 0 || _labels.length==0){
					alert("更新信息存在逻辑错误，请修正");
					return false;
				}

				updateQuestion(_text, _attribute_name, {
					is_rand: _is_rand,
					show_style: _show_style,
					item_num_per_group: _item_num_per_group,
					show_unknown: _show_unknown,
					items: _items,
					labels: _labels
				})
				break;
			default: 
				alert("未实现此类型功能");
		}

		return false;
	});

	// not complete question should be deleted
	$('.btn-not-complete-delete').removeAttr('disabled').css('float', 'right');
	$('.btn-not-complete-delete').click(function(){
		$('.redBtn').attr('disabled','disabled');
		$.delete('/admin/template_questions/'+window.location.pathname.split('/')[3], 
			function(data){
				$('.redBtn').removeAttr('disabled');
				if(data.success){
					alert("删除成功,跳到列表页面!");
					window.location.replace("/admin/template_questions");
				}else{
					if(data.value.error_code == undefined){
						alert("删除失败");
					}else{
						var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
						alert(info);
					}
				}
			});
	});

	// *********************
	//
	// new page
	// 
	// ****************************

	$('#new-tab .btn-new-ok').click(function(){
		//verify present
		$('.blueBtn').attr('disabled','disabled');
		var _qt = $('#new-tab select[name=question_type]').val().trim();
		$.post('/admin/template_questions', 
			{question_type: parseInt(_qt)},
			function(data){
				// console.log(data);
				$('.blueBtn').removeAttr('disabled');
				if(data.success){
					alert("创建成功");
					window.location.replace("/admin/template_questions/"+data.value._id.toString());
				}else{
					if(data.value.error_code == undefined){
						alert("创建失败");
					}else{
						var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
						alert(info);
					}
				}

			});
		
	});

});