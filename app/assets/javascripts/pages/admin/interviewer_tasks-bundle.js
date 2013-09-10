jQuery(function($) {

	// ***************
	//
	// index  page
	//
	// *************

	// replace id to email
	$.each($('.user_id'), function(index,item){
		var user_id =$(item).attr('name').trim();
		var survey_id = $(item).closest('tr').attr('id');
		// console.log(survey_id);
		$.get("/admin/"+user_id+"/get_email", function(data){
			// console.log(data);
			if(data.success){
				$('.user_id[name='+user_id+']').text(data.value).removeClass('user_id');
			}
		});
		return null;
	});

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
		$.delete('/admin/publishes/'+_id, {}, function(data){return_function(data, _id)});
		return false;
	});

	//delete all data
	$('.delete-selected').click(function(e){
		e.stopPropagation();
		//delete all data from database	
		if($('tbody :checkbox[checked="checked"]').size() == 0){
			alert('未存在选择项');
			return false;
		}
		var conf = confirm('确定删除所选项吗？');
		if(conf){
			$('tbody :checkbox[checked="checked"]').each(function(){
				var _id = $(this).closest('tr').attr('id');
				$.delete('/admin/publishes/'+_id, {}, function(data){return_function(data, _id)});
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

	//search
	$('.btn-search').click(function(){
		var searchType = $('select[name=search]').val();
		var searchValue = $('input[name=search]').val();
		window.location.replace('/admin/publishes?'+searchType+'='+searchValue);
		return false;
	});

	// ***************
	//
	// new  page
	//
	// *************

	// load system_user of type
	function loadSystemUser(system_user_type){
		$('.btn-allocate-ok').attr('disabled','disabled');
		$.get('/admin/users.json?deleted=false&per_page=100&role='+system_user_type,function(data){
			// console.log(data);
			$('select.system_user').empty();
			$('.blueBtn').removeAttr('disabled');
			if(data.success){
				$.each(data.value.data, function(index, item){
					var $option = $('<option value=""></option>');
					$option.val(item._id).text(item.email);
					$('select.system_user').append($option);
				});
			}else{
				if(data.value.error_code == undefined){
					alert("加载失败");
				}else{
					var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
					alert(info);
				}
			}
		});
	}

	if($('.interviewer_task #new-tab').length > 0){
		// list page does not take this action.
		loadSystemUser(2);
	}

	$('.rules li').click(function(){
		$('.rules li').removeClass('selected');
		$(this).addClass('selected');
	})
});