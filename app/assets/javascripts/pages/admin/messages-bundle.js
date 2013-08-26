//=require ui/widgets/od_tip

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
		$.delete('/admin/messages/'+_id, {}, function(data){return_function(data, _id)});
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
				$.delete('/admin/messages/'+_id, {}, function(data){return_function(data, _id)});
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
		window.location.replace('/admin/messages?'+searchType+'='+searchValue);
		return false;
	});

	// **********************
	// show/edit page
	// 
	// ***********************

	$('.btn-edit-ok').click(function() {
		$('.blueBtn').attr('disabled', 'disabled');
		var _title = $('#edit-tab [name="message[:title]"]').val().trim();
		var _receiver = $('#edit-tab [name="message[:receiver]"]').val().trim();
		var _content = $('#edit-tab [name="message[:content]"]').val().trim();

		if(_title == "" || _content == ""){
			alert("标题与内容都不能为空");
			return false;
		}

		$.put('/admin/messages/'+window.location.pathname.split('/')[3],
			{
				title: _title,
				receiver: _receiver,
				content: _content
			}, 
			function(data){
				// console.log(data);
				$('.blueBtn').removeAttr('disabled');
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
		$('.blueBtn').attr('disabled', 'disabled');

		var _title = $('#new-tab [name="message[:title]"]').val().trim();
		var _receiver = $('#new-tab [name="message[:receiver]"]').val().trim();
		var _content = $('#new-tab [name="message[:content]"]').val().trim();

		if(_title == "" || _content == ""){
			alert("标题与内容都不能为空");
			return false;
		}

		$.post('/admin/messages',
			{
				title: _title,
				receiver: _receiver,
				content: _content
			}, 
			function(data){
				// console.log(data);
				$('.blueBtn').removeAttr('disabled');
				if(data.success){
					alert("创建成功");
					window.location.replace('/admin/messages');
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