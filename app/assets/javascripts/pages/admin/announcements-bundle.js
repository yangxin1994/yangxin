jQuery(function($) {
	// ***************
	//
	// index page
	//
	// *************
	
	$("table th:first span").hide();
	$("table th:last span").hide();
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
		$.delete('/admin/announcements/'+_id, {}, function(data){return_function(data, _id)});
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
				$.delete('/admin/announcements/'+_id, {}, function(data){return_function(data, _id)});
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
		window.location.replace('/admin/announcements?'+searchType+'='+searchValue);
		return false;
	});

});