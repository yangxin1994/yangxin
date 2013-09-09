jQuery(function($) {

	// ***************
	//
	// index,whites,blacks,deleted  page
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
		$.delete('/admin/users/'+_id, {}, function(data){return_function(data, _id)});
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
				$.delete('/admin/users/'+_id, {}, function(data){return_function(data, _id)});
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
		var includeBlock = 0;
		if ($('input[name=include_block]').is(':checked')) {
			includeBlock = 1
		}
		window.location.replace('/admin/users?'+searchType+'='+searchValue + '&include_block=' + includeBlock);
		return false;
	});


	//***************
	//
	//  show page
	//
	//***********************
	$('.edit-tab').hide(); // maybe css conflict, do not able to use addClass('dn')
	$('.btn-edit-ok').hide();
	$('#edit-tab input[name^="user"]').attr('disabled', 'disabled');

	//to modify
	$('.btn-edit').click(function(){
		//tab
		$('.show-tab').hide();
		$('.edit-tab').show();
		$('.tab').removeClass('current');
		$('.edit-tab').addClass('current');
		//btn
		$('.btn-edit-ok').show();
		$('.btn-edit').hide();

		//able edit
		$('#edit-tab input').not('#edit-tab input[name="user[:email]"]').removeAttr('disabled');

		return false;
	});

	$('.btn-edit-ok').click(function() {
		var _email = $('#edit-tab input[name="user[:email]"]').val();
		var _username=$('#edit-tab input[name="user[:username]"]').val();
		var _full_name=$('#edit-tab input[name="user[:full_name]"]').val();
		var _identity_card=$('#edit-tab input[name="user[:identity_card]"]').val();
		var _company=$('#edit-tab input[name="user[:company]"]').val();
		var _phone=$('#edit-tab input[name="user[:phone]"]').val();
		var _address=$('#edit-tab input[name="user[:address]"]').val();

		$.put('/admin/users/'+window.location.pathname.split('/')[3],
			{user:
				{
					email: _email,
					username: _username,
					full_name: _full_name,
					identity_card: _identity_card,
					company: _company,
					phone: _phone,
					address: _address
				}
			},
			function(data){
				if(data.success){
					alert("更新成功");
					//maybe not fit for IE name^="user"
					$('#edit-tab input[name^="user"]').attr('disabled', 'disabled');
					$('.btn-edit').show();
					$('.btn-edit-ok').hide();
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

		return false;
	});

	// reset to system password
	$('.btn-reset-ok').click(function(){
		$.put('/admin/users/'+window.location.pathname.split('/')[3]+'/reset_password',
			{}
			,function(data){
				console.log(data);
				if(data.success){
					alert("更新成功<br/>新密码为："+data.value.new_password+"<br/>或者请注册邮箱查看！");
				}else{
					if(data.value.error_code == undefined){
						alert("更新失败");
					}else{
						var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
						alert(info);
					}
				}
		});
		return false;
	});

	//change color
	$('.btn-to-color-ok').click(function(){
		var color_int = parseInt($(this).attr('value'));
		$.put('/admin/users/'+window.location.pathname.split('/')[3]+'/set_color',
			{color: color_int}
			,function(data){
				console.log(data);
				if(data.success){
					alert("更新成功");
					window.location.reload();
				}else{
					if(data.value.error_code == undefined){
						alert("更新失败");
					}else{
						var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
						$alert(info);
					}
				}
		});
		return false;
	});

	//set to delete
	$('.btn-to-delete-ok').click(function(){
		$.delete('/admin/users/'+window.location.pathname.split('/')[3],
			function(data){
				// console.log(data);
				if(data.success){
					alert("删除成功");
					window.location.reload();
				}else{
					if(data.value.error_code == undefined){
						alert("删除失败");
					}else{
						var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
						alert(info);
					}
				}
		});
		return false;
	});

	//recover
	$('.btn-to-recover-ok').click(function(){
		$.put('/admin/users/'+window.location.pathname.split('/')[3]+'/recover',
			function(data){
				// console.log(data);
				if(data.success){
					alert("恢复成功");
					window.location.reload();
				}else{
					if(data.value.error_code == undefined){
						alert("恢复失败");
					}else{
						var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
						alert(info);
					}
				}
		});
		return false;
	});

	$('.btn-point-ok').click(function(){
		var _point=parseInt($('#f_point').val());
		var _cause_desc = parseInt($('#f_cause_desc').val());
		if(_point.toString()=='NaN'){
			alert("请输入正确的数字格式");
			$('#f_point').val('');
			return false;
		}
		$.put('/admin/users/'+window.location.pathname.split('/')[3]+'/add_point',
			{
			  point: _point,
			  cause_desc: _cause_desc
			},
			function(data){
				// console.log(data);
				if(data.success){
					alert("增加积分成功");
					window.location.reload();
				}else{
					if(data.value.error_code == undefined){
						alert("增加积分失败");
					}else{
						var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
						alert(info);
					}
				}
		});
		return false;
	});

	// lock
	$('.btn-lock-ok').click(function(){
		$.put('/admin/users/'+window.location.pathname.split('/')[3]+'/set_lock',
			{lock: true}
			,function(data){
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
		return false;
	});

	// unlock
	$('.btn-unlock-ok').click(function(){
		$.put('/admin/users/'+window.location.pathname.split('/')[3]+'/set_lock',
			{lock: false}
			,function(data){
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
		return false;
	});

	// change_role fn
	$('.btn-role-ok').click(function(){
		var roles=0;
		$.each($('.role input:checked'), function(index,item){
			var role = parseInt($(item).val());
			roles += role;
		});
		$.put('/admin/users/'+window.location.pathname.split('/')[3]+'/set_role',
			{role: roles}
			,function(data){
				console.log(data);
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
		});
		return false;
	});

	// *********************
	//
	// new page
	//
	// ****************************
	function is_email(a){
		return /^([\w!.%+\-])+@([\w\-])+(?:\.[\w\-]+)+$/.test(a);
	}

	$('#new-tab input.password').change(function(){
		if($(this).attr('checked') == 'checked'){
			// $('tbody :checkbox').attr('checked','checked');
			$('.password_text').text('系统密码');
			$('#new-tab input[name="user[:password]"]').val('').attr('disabled', 'disabled');
			$('.sp-tip').css('display', 'inline')
		}
		else{
			// $('tbody :checkbox').removeAttr('checked');
			$('.password_text').text('密码');
			$('#new-tab input[name="user[:password]"]').removeAttr('disabled');
			$('.sp-tip').css('display', 'none')
		}
	});

	$('#new-tab input[name="user[:email]"]').blur(function(){
		if(!is_email(this.value)){
			$(this).addClass('error');
			$(this).next().text('请输入正确的邮箱');
		}else{
			$(this).removeClass('error');
			$(this).next().text('');
		}
	});

	function postNewUser(data){
		// console.log(data);
		if(data.success){
			alert("创建成功");
			$('#new-tab input[name^="user"]').val('');
			// $('#new-tab input.btn-new-ok').attr('disabled', 'disabled').addClass('od-button-disable');

		}else{
			if(data.value.error_code == undefined){
				alert("创建失败");
			}else{
				// var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
				var info ="好像出了什么差错呢" + data.value.error_message;
				alert(info);
			}
		}
	}

	$('#new-tab .btn-new-ok').click(function(){
		//verify present
		var _email = $('#new-tab input[name="user[:email]"]').val().trim();
		var _full_name=$('#new-tab input[name="user[:full_name]"]').val().trim();
		var _password=$('#new-tab input[name="user[:password]"]').val().trim();
		var _type = $('#new-tab select[name=type]').val().trim();

		if(_email == "" || _full_name == ""){
			alert("邮箱和姓名都不能为空");
			return false;
		}

		if(!is_email(_email)){
			alert("请输入正确的邮箱");
			return false;
		}

		if(_password == ""){
			$.post('/admin/users',
				{email: _email, full_name: _full_name, system_user_type: _type},
				function(data){postNewUser(data)});
		}else{
			$.post('/admin/users',
				{email: _email, full_name: _full_name, system_user_type: _type, password: _password},
				function(data){postNewUser(data)});
		}

	});
});
