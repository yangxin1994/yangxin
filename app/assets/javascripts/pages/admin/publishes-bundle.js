jQuery(function($) {

	// ***************
	//
	// list  page
	//
	// *************

	// replace id to email
	$.each($('.user_id'), function(index,item){
		var user_id =$(item).attr('name').trim();
		var survey_id = $(item).closest('tr').attr('id');
		// console.log(survey_id);
		$.getJSON("/admin/"+user_id+"/get_email", function(data){
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
		$.deleteJSON('/admin/publishes/'+_id, {}, function(data){return_function(data, _id)});
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
				$.deleteJSON('/admin/publishes/'+_id, {}, function(data){return_function(data, _id)});
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

	// is_show_in_community
	$('input[name=is_show_in_community]').change(function(){
		var params = $('.show_community').attr('params');
		if(this.checked)
		{
			window.location.replace('/admin/publishes?show_in_community=true'+params);
		}else{
			window.location.replace('/admin/publishes?show_in_community=false'+params);
		}
	});

	// ***************
	//
	// show/edit  page
	//
	// *************

	// change style from brain frame
	if($('#edit-tab').length > 0){
		$('#footer').css('position', 'relative');
	}

	// set reward checkbox change
	$('#set-reward').change(function(){
		if(this.checked){
			$('#reward-prize').removeAttr('disabled')
			$('#reward-point').removeAttr('disabled')
		}else{
			$('#reward-prize').attr('disabled', 'disabled')
			$('#reward-point').attr('disabled', 'disabled')
		}
	})

	// when first load set-reward checkbox
	if($('#set-reward:checked').size() == 0){
		$('#reward-prize').attr('disabled', 'disabled')
		$('#reward-point').attr('disabled', 'disabled')
	}

	// load lotteries
	function loadLotteries(){
		$('.btn-reward-ok').attr('disabled', 'disabled');
		$.getJSON('/admin/lotteries?scope=quillme&per_page=100', function(data){
			// console.log(data);
			if(data.success){
				$('select.reward').empty();
				$.each(data.value.data, function(index, item){
					var $option = $('<option value=""></option>');
					var _title = item.title.toString();
					if(_title.length>32){
						_title=_title.substr(0,32)+"..."
					}
					$option.val(item._id).text(_title);
					$('select.reward').append($option);
				});	

				if($('.current-lottery').attr('name')!=""){
					var _id = $('.current-lottery').attr('name');
					if($('select.reward option[value='+_id+']').length > 0){
						$('select.reward').val($('.current-lottery').attr('name'));	
					}else{
						$('.current-lottery').empty().append('<span>之前选择的抽奖现为非显示状态, <a class="f-orange" href="/admin/lotteries/'+_id+'">之前活动</a></span>')
					}					
				}
				
			}else{
				if(data.value.error_code == undefined){
					alert("操作失败");
				}else{
					var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
					alert(info);
				}
			}
			$('.btn-reward-ok').removeAttr('disabled');
		});
	}

	// if reward is enabled and prized, load lotteries!
	if($('input[name=reward]:checked').val()=="1"){
		$('.current-lottery').removeClass('dn');
		loadLotteries();
	}

	// load activity lotteries
	$('input[name=reward]').click(function(){
		// console.log($('input[name=reward]').attr('checked'));
		if($('input[name=reward]:checked').val()=="1"){
			loadLotteries();
		}
	});

	// persistence of reward operation
	$('.btn-reward-ok').click(function() {
		$('.btn-reward-ok').attr('disabled','disabled');

		var _lottery_id = $('#edit-tab select.reward').val();
		var _point=parseInt($('#edit-tab input[name="survey[:point]"]').val());
		var _reward=0;
		if($('#set-reward:checked').size() != 0){
			_reward = parseInt($('#edit-tab input[name="reward"]:checked').val())
		}

		if(parseInt(_reward)==1 && _lottery_id == null){
			alert("未选择活动!");
			$('.btn-reward-ok').removeAttr('disabled');
			return false;
		}

		$.putJSON('/admin/publishes/'+window.location.pathname.split('/')[3]+'/add_reward',
			{
				lottery_id: _lottery_id,
				point: _point,
				reward: _reward
			}, 
			function(data){
				if(data.success && data.value==true){
					alert("更新成功");
					if(parseInt(_reward)==1 ){
						$('.current-reward').empty().append('<span>奖励指定<a class="f-red" href="/admin/lotteries/'+_lottery_id+'">活动</a></span>');
					}else{
						$('.current-reward').empty().append('<span>奖励积分<b class="f-red">'+_point+'</b></span>');
					}
				}else{
					if(data.value.error_code == undefined){
						alert("更新失败");
					}else{
						var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
						alert(info);
					}
				}
				$('.btn-reward-ok').removeAttr('disabled');
			}
		);

		return false;
	});

	// close survey
	$('.close-survey').click(function(){
		$.putJSON('/admin/reviews/'+window.location.pathname.split('/')[3]+'/close', 
			{},
			function(data){
				// console.log(data);
				if(data.success){
					alert("操作成功");	
					window.location.replace('/admin/publishes');
				}else{
					if(data.value.error_code == undefined){
						alert("操作失败");
					}else{
						var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
						alert(info);
					}
				}
			});
		
		return false;
	});

	$('.input-int').blur(function(){
		if(parseInt($(this).val()).toString()=="NaN"){   
			$(this).addClass('error');
			$(this).next().text('请输入数字');
		}else{
			$(this).removeClass('error');
			$(this).next().text('');
		}
	});

	$('.btn-spread-ok').click(function() {
		$('.btn-spread-ok').attr('disabled','disabled');
		var _spreadable = $('#edit-tab input[name="survey[:spreadable]"]')[0].checked;
		var _spread_point=$('#edit-tab input[name="survey[:spread_point]"]').val();

		$.putJSON('/admin/publishes/'+window.location.pathname.split('/')[3]+'/set_spread',
			{
				spreadable: _spreadable,
				spread_point: _spread_point
			}, 
			function(data){
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
				$('.btn-spread-ok').removeAttr('disabled');
			}
		);
		
		return false;
	});

	$('.btn-community-ok').change(function() {
		$(this).attr('disabled','disabled');
		if($('.btn-community-ok:checked').length > 0){
			$.putJSON('/admin/publishes/'+window.location.pathname.split('/')[3]+'/set_community',
				{}, 
				function(data){
					if(data.success){
						alert("发布至 Quillme 成功");
					}else{
						if(data.value.error_code == undefined){
							alert("发布至 Quillme 失败");
						}else{
							var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
							alert(info);
						}
					}
					$('.btn-community-ok').removeAttr('disabled');
				}
			);
		}else{
			$.putJSON('/admin/publishes/'+window.location.pathname.split('/')[3]+'/cancel_community',
				{}, 
				function(data){
					if(data.success){
						alert("取消发布至 Quillme 成功");
						
					}else{
						if(data.value.error_code == undefined){
							alert("取消发布至 Quillme 失败");
						}else{
							var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
							alert(info);
						}
					}
					$('.btn-community-ok').removeAttr('disabled');
				}
			);
		}
		
		return false;
	});

	$('#reviewable_ckb').change(function() {
		$.putJSON('/admin/publishes/'+window.location.pathname.split('/')[3]+'/set_answer_need_review',
			{ answer_need_review: !$(this).is(':checked') },  function(data){ if(data.success){ alert("设置成功"); }}
		);
	});

	// load system_user of type
	function loadSystemUser(system_user_type, selector){
		$('.btn-allocate-ok').attr('disabled','disabled');
		$.getJSON('/admin/users?deleted=false&per_page=100&role='+system_user_type,function(data){
			// console.log(data);
			$(selector).empty();
			if(data.success){
				// $('select.system_user').empty();
				$.each(data.value.data, function(index, item){
					var $option = $('<option value=""></option>');
					$option.val(item._id).text(item.email);
					$(selector).append($option);
				});

				$('.btn-allocate-ok').removeAttr('disabled');
			}else{
				if(data.value.error_code == undefined){
					alert("加载失败");
				}else{
					var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
					alert(info);
				}
				$('.btn-allocate-ok').removeAttr('disabled');
			}
		});
	}
	
	//first load answer_auditor
	if($('.publishes #edit-tab').length > 0){
		// list page does not take this action.
		loadSystemUser(4, 'select.system_user');
	}

	if($('select.select-interviewer').length > 0){
		loadSystemUser(2, 'select.select-interviewer');
	}

	//system_user_type change
	$('select.system_user_type').change(function(){
		var _system_user_type=$('select.system_user_type').val();
		loadSystemUser(_system_user_type, 'select.system_user');
		return false;
	});

	// replace id to email
	$.each($('.allocate_user_id'), function(index,item){
		var user_id =$(item).parent().attr('name');
		$.getJSON("/admin/"+user_id+"/get_email", function(data){
			if(data.success){
				$('[name='+user_id+'] .allocate_user_id').text(data.value).removeClass('allocate_user_id');
			}
		});
		return null;
	});

	$('.allocate_users .allocate_user_delete').bind('click', function(){
		var $allocate_user = $(this).parent();
		var _system_user_type = $allocate_user.parent().attr('id');
		var _user_id = $allocate_user.attr('name');
		$.putJSON('/admin/publishes/'+window.location.pathname.split('/')[3]+'/allocate',
			{
				system_user_type: _system_user_type,
				user_id: _user_id,
				allocate: false
			},
			function(data){
				// console.log(data);
				if(data.success){
					$allocate_user.remove();
				}else{
					if(data.value.error_code == undefined){
						alert("操作失败");
					}else{
						var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
						alert(info);
					}
				}
		});
	});

	$('.btn-allocate-ok').click(function(){
		$(this).attr('disabled', 'disabled');
		var _system_user_type_int = parseInt($('select.system_user_type').val());
		var _system_user_type = '';
		if(_system_user_type_int==4){
			_system_user_type = 'answer_auditor';
		}else if(_system_user_type_int==1){
			_system_user_type = 'entry_clerk';
		}else if(_system_user_type_int==2){
			_system_user_type = 'interviewer';
		}
		var _user_id = $('select.system_user').val();
		var _user_email = $('select.system_user option:selected').text();

		if($('#'+_system_user_type+' .allocate_user[name='+_user_id+']').length > 0){
			alert("已经存在此用户!");
			$('.btn-allocate-ok').removeAttr('disabled');
			return false;
		}

		$.putJSON('/admin/publishes/'+window.location.pathname.split('/')[3]+'/allocate',
			{
				system_user_type: _system_user_type,
				user_id: _user_id,
				allocate: true
			},
			function(data){
				// console.log(data);
				if(data.success){
					var $allocate_user= $('<div class="bg-orange allocate_user" name="">'+
						        			'<span class=""></span>'+
						        			'<a href="#set_system_user" class="bg-red allocate_user_delete"> - </a>'+
						        		'</div>')
	        		$allocate_user.attr('name', _user_id);
	        		$allocate_user.children('span').text(_user_email);
	        		$('#'+_system_user_type).append($allocate_user);

	        		$('.btn-allocate-ok').removeAttr('disabled');
				}else{
					if(data.value.error_code == undefined){
						alert("操作失败");
					}else{
						var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
						alert(info);
					}
					$('.btn-allocate-ok').removeAttr('disabled');
				}
		});
		return false;
	});

	// add new interviewer-task
	$('.new-task-ok').click(function(){
		if(parseInt($('.new-task input[name="task-amount"]').val()).toString()=="NaN"){
			alert("操作失败, 请输入正确数字!");
			return false;
		}
		if($('ul.tasks').children('[name='+$('.select-interviewer').val()+']').length > 0){
			alert("己存在此人员的任务!");
			return false;
		}
		$('.new-task-ok').attr('disabled','disabled');
		var _user_id = $('.new-task select.select-interviewer').val();
		var _quota_amount = parseInt($('.new-task input[name="task-amount"]').val());
		var _user_email = $('.new-task select.select-interviewer :selected').text();
		$.postJSON(window.location.pathname + '/interviewer_tasks', 
			{
				user_id: _user_id,
				quota: 
				{
					rules: [{amount: _quota_amount}]
				}
			},
			function(data){
				// console.log(data);
				if(data.success){
					// reset task-amount to empty
					$('.new-task input[name="task-amount"]').val('');

					var $item = $('.interviewer-task-item').clone(true);
					$item.removeClass().attr('id', data.value._id);
					$item.attr('name', data.value.user_id);
					$item.find('.interviewer').text(_user_email);
					$item.find('[name="task-amount"]').val(data.value.quota.rules[0].amount);
					$item.appendTo('ul.tasks');
				}else{
					if(data.value.error_code == undefined){
						alert("操作失败");
					}else{
						var info = data.value.error_code+" : "+data.value.error_message;
						alert(info);
					}
				}
				$('.new-task-ok').removeAttr('disabled');
			})

	});

	// update interviewer-task
	$('.update-task-ok').click(function(){
		var _task_id = $(this).closest('li').attr('id');

		if(_task_id == ""){
			alert("页面加载有误,　请重新加载页面!");
			return false;
		}

		if($(this).closest('li .error').length > 0){
			alert("操作失败, 请输入正确数字!");
			return false;
		}
		$('#'+_task_id+' .update-task-ok').attr('disabled','disabled');
		var _quota_amount = parseInt($(this).closest('li').find('input[name="task-amount"]').val());
		$.putJSON(window.location.pathname + '/interviewer_tasks/'+_task_id, 
			{
				quota: 
				{
					rules: [{amount: _quota_amount}]
				}
			},
			function(data){
				console.log(data);
				if(data.success){
					alert("更新成功!");
				}else{
					if(data.value.error_code == undefined){
						alert("操作失败");
					}else{
						var info = data.value.error_code+" : "+data.value.error_message;
						alert(info);
					}
				}
				$('#'+_task_id+' .update-task-ok').removeAttr('disabled');
			})

	});

	// delete interviewer-task
	$('.delete-task').click(function(){
		var _task_id = $(this).closest('li').attr('id');

		if(_task_id == ""){
			alert("页面加载有误,　请重新加载页面!");
			return false;
		}

		$('#'+_task_id+' .delete-task').attr('disabled','disabled');
		$.deleteJSON(window.location.pathname + '/interviewer_tasks/'+_task_id, 
			function(data){
				console.log(data);
				if(data.success){
					$('ul.tasks li#'+_task_id).remove();
				}else{
					if(data.value.error_code == undefined){
						alert("操作失败");
					}else{
						var info = data.value.error_code+" : "+data.value.error_message;
						alert(info);
					}
				}
				$('#'+_task_id+' .delete-task').removeAttr('disabled');
			})

	});

	// promotable
	$('#promotable_btn').click(function() {
		var promotable = $('#promotable_ckb').is(':checked');
		var promote_email_number = parseInt($('#promotable_ipt').val());
		if(promotable && promote_email_number <= 0) {
			alert('邮件推广数量需要为正整数');
			return;
		}
		$('#promotable_ipt').val(promote_email_number);

		$.util.disable($('#promotable_btn'));
		$.putJSON('/admin/publishes/'+window.location.pathname.split('/')[3]+'/set_promotable', {
			promotable: promotable,
			promote_email_number: promote_email_number
		}, function(retval) {
			$.util.enable($('#promotable_btn'))
			if(retval.success) {
				alert('更新成功');
			} else {
				alert('更新失败，请重试。');
			}
		});
	});
	// $('#promotable_ckb').change(function() {
	// 	$.putJSON('/admin/publishes/'+window.location.pathname.split('/')[3]+'/set_promotable', {
	// 		promotable: $(this).is(':checked')
	// 	}, function(retval) {
	// 		if(retval.success) {
	// 			alert('更新成功');
	// 		} else {
	// 			alert('更新失败，请重试。');
	// 			location.reload(true);
	// 		}
	// 	});
	// });

	// ***********END********
});