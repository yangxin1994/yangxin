//=require ui/widgets/od_icon_buttons
//=require ui/widgets/od_white_button
//=require ui/widgets/od_checkbox
//=require ui/widgets/od_popup

jQuery(function($) {

	// white button
	// var wbtn = $.od.odWhiteButton({icon: 'del'});
	// wbtn.appendTo('#refresh_btn');
	// icon buttons
	var icon_buttons = $.od.odIconButtons({
		buttons: [{
			name: 'del',
			info: '批量删除'
		}]
	}).appendTo('#control_panel');

	// **********remote star action**************
	$('em.icon-star').click(function(){
		var survey_id = $(this).closest('.question-box').attr('id');
		var is_star = !$(this).hasClass('star-active');
		if(is_star)
			$(this).addClass('star-active');
		else
			$(this).removeClass('star-active');
		$.putJSON('/questionaires/'+survey_id+"/update_star", { is_star: is_star }, 
			function(data){
				if(data.success){
					// console.log(data);
					if(data.value){
						$("#"+survey_id+" em.icon-star").addClass('star-active');
					}else{
						$("#"+survey_id+" em.icon-star").removeClass('star-active');
					}
				}else{
					//TODO: more friendly
					var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
					$.od.odPopup({content: info});
				}
			});

		return false;
	});


	// *********remote delete/recover/remove action *****************
	function return_function(data,survey_id){
		// console.log(data);
		if(data.value){
			$("#"+survey_id).slideUp('slow', function(){$(this).remove();});
		}else{
			//TODO: more friendly
			var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
			$.od.odPopup({content: info});
		}
	};

	$('em.icon-del').click(function(){
		var survey_id = $(this).closest('.question-box').attr('id');
		$.deleteJSON('/questionaires/'+survey_id+'.json', {}, function(data){return_function(data, survey_id)});
	});

	$('em.icon-recover').click(function(){
		var survey_id = $(this).closest('.question-box').attr('id');
		$.putJSON('/questionaires/'+survey_id+'/recover.json', {}, function(retval){return_function(retval, survey_id)});
	});

	$('em.icon-remove').click(function(){
		var $thiss = $(this);
		$.od.odPopup({
			type:'confirm',
			content: '确定彻底删除此问卷?',
			confirm:function(){
				var survey_id = $thiss.closest('.question-box').attr('id');
				$.get('/questionaires/'+survey_id+'/remove', {}, function(data){return_function(data, survey_id)});	
			}
		});
	});

	// *************checkbox del*****************
	$('input.check-all[type="checkbox"]').click(function(){
		if(this.checked){
			$('input.list-check').attr('checked', 'checked');
		}else{
			$('input.list-check').removeAttr('checked');
		}
	});

	$('.list-check[type="checkbox"]').click(function(){
		if(this.checked){
			$(this).attr('checked', 'checked');
		}else{
			$(this).removeAttr('checked');
		}
	});

	$('.od-icon-del').parent().click(function(){
		if($('.list-check[type="checkbox"][checked="checked"]').size() == 0){
			$.od.odPopup({content:'未存在选择问卷' });
			return false;
		}
		$.od.odPopup({type:'confirm',
			content: '确定删除所选问卷吗？',
			confirm:function(){
				$('.list-check[type="checkbox"][checked="checked"]').each(function(){
					var survey_id = $(this).closest('.question-box').attr('id');
					$.deleteJSON('/questionaires/'+survey_id+'.json', {}, function(data){return_function(data, survey_id)});
				});
			}
		});
	});

	if($('.question-box').length < window.per_page){
		$('.not-anymore').removeClass('dn');
	}

});