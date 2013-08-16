//=require jquery.placeholder
//=require jquery.cookie
jQuery(function($) {
	//var mobile_partten = /^(1(([35][0-9])|(47)|[8][0126789]))\d{8}$/;
	var mobile_partten = /^(13[0-9]|15[012356789]|18[0236789]|14[57])[0-9]{8}$/
	var email_partten = /^(\w)+(\.\w+)*@(\w)+((\.\w{2,3}){1,3})$/;

	//如果用户已经关闭了安装插件提示，那么24小时内不再提示安装
	if($.cookie('ignore_plugin')){
		$('div.hot-research-banner').remove();
	}

	//用户点击关闭安装插件提示，生成cookie，记录用户决定
	$('.hot-research-banner .popup-close').click(function(){
		$(this).parent('.hot-research-banner').remove();
		// write cookie 
		$.cookie('ignore_plugin', 'true', { expires: 1 });
	})


	// $('select[name="answer_status"]').change(function(){
	// 	status = ($.util.param('status') ? ($.util.param('status')) : '')
	// 	reward_type = ($.util.param('reward_type') ? ($.util.param('reward_type')) : '')
	// 	answer_status = $(this).val()
	// 	window.location.href = "/surveys?status=" + status  + "&reward_type=" + reward_type + "&answer_status=" + answer_status
	// })


  //下拉框点击事件
	$("body").click(function(e){
		var select = $(e.target).hasClass('select') || $(e.target).parents('div').hasClass('select')
		if(select && $(e.target).prop('tagName') != 'LI'){	
				$(e.target).closest('.select-content').addClass('active').siblings('ul').show()	
		}else{
			$('.select-content').siblings('ul').hide()
			$('.select-content').removeClass('active')					
		}
	})


	var select = $('div.select')
	if (select.length > 0){
		$(select).toggle(function(){
			if($(this).children('ul').is(':visible')){
				$(this).children('.select-content').removeClass('active').end().children('ul').hide()
			}else{
				$(this).children('.select-content').addClass('active').end().children('ul').show()				
			}	
		},function(){
			if($(this).children('ul').is(':visible')){
				$(this).children('.select-content').removeClass('active').end().children('ul').hide()
			}else{
				$(this).children('.select-content').addClass('active').end().children('ul').show()				
			}	
		})
	}


  //下拉框选项点击事件
  $('.select-content').next('ul').children('li').click(function(){
  	$('span.select-txt').attr('data',$(this).attr('data')).text($(this).text())
	var status = ($.util.param('status') ? ($.util.param('status')) : '')
	var reward_type = ($.util.param('reward_type') ? ($.util.param('reward_type')) : '')
	var answer_status = $(this).attr('data')
  	window.location.href = "/surveys?status=" + status  + "&reward_type=" + reward_type + "&answer_status=" + answer_status
  })


	//用户点击开放状态tab，发送ajax请求
	// $('.rl_h ul li').on('click',function(){
	//   $(this).siblings('li').removeClass('current').end().addClass('current');	  
	//   status = $(this).attr('data')
	//   $('ul.reward_type li').removeClass('current').attr('status',status).first().addClass('current');
	// 	$('select option').attr('status',status);
	// 	$('select option:first').attr('selected','selected');
	// 	$('.pagination a').attr('status',status);
	// 	get_reward_type_count(status)
	// 	get_special_status_surveys(status)
	// })

	//用户点击奖励类型tab发送ajax请求
	// $('ul.reward_type li').on('click',function(){
	// 	$(this).siblings('li').removeClass('current').end().addClass('current');
	// 	status      = $(this).attr('status')
	// 	reward_type = $(this).attr('reward_type')
	// 	status      = status === "undefined" ? 2 : status
	// 	$('.pagination a').attr('status',status);
	// 	$('.pagination a').attr('reward_type',reward_type);
	// 	if(reward_type){
	// 	  $('select option[value="'+ reward_type +'"]').attr('selected','selected');	
	// 	}else{
	// 		$('select option:first').attr('selected','selected');	
	// 	}
		
	// 	get_special_status_surveys(status,reward_type)
	// })

	//用户利用下拉框来展示不同类型的调研
	// $('select').change(function(){
	// 	reward_type = $(this).val();
	// 	status      = $(this).attr('status')
	// 	status      = status === "undefined" ? 2 : status
	// 	$('.pagination a').attr('status',status);
	// 	if (reward_type){
	// 		$('ul.reward_type').find("[reward_type='"+reward_type+"']").siblings().removeClass('current').end().addClass('current');	
	// 		$('.pagination a').attr('reward_type',reward_type);
	// 	}else{
	// 		$('ul.reward_type li:first').siblings().removeClass('current').end().addClass('current');
	// 	}
	// 	get_special_status_surveys(status,reward_type) 
	// })

	//ajax  分页
	// $('.pagination a').live('click',function(){
	// 	page        = $(this).attr('page')
	// 	status      = $(this).attr('status')
	// 	status      = status === "undefined" ? 2 : status
	// 	reward_type = $(this).attr('reward_type')
	// 	reward_type = reward_type === "undefined" ? 0 : reward_type
	// 	get_special_status_surveys(status,reward_type,page)
	// 	return false;
	// })

  //关闭弹出框
	$('button.close_f').live('click',function(){
		$.fancybox.close();
	})

  //现在激活邮箱 button
	$('button.mail_act_now').click(function(){
		var link = $(this).attr('href');
		link = 'http://www.' + link;
		window.location.href = link;
	})

  //重新发送邮箱激活链接
	$('a.re_mail').live('click',function(){
		var mail = $('span.mail').text();
		re_generate_email_activate($(this),mail);
	})
  //重新发送手机验证码
	$('a.re_mobile').live('click',function(){
		var mobi = $('span.mobi').text();
		$('div.error').remove();
		re_generate_email_activate($(this),mobi);
	})

  //手机验证
	$('button.next_f').live('click',function(){
		var butt = $(this);
		var channel = $('.mobi').text();
		var code    = $('input[name="code"]').val()
		if (code.length > 5){
			$.ajax({
				type: "get",
				url: '/surveys/make_rss_mobile_activate',
				data: {rss_channel:channel,code:code},
				beforeSend:function(){
					butt.next('span').remove();
				},
				success:function(retval){
					butt.next('span').remove();
					if(retval){
						popup('#mobile_finish',null,null)	
					}else{
						butt.after('<div>验证码错误或者已过期,请重新生成</div>');
					}
					
				}
			})
		}else{
			$('input[name="code"]').focus();
		}

	})

  //订阅按钮
	$('input[name="contact"]').next('a').click(function(){
		var channel = $('input[name="contact"]').val();
		if(email_partten.test(channel) || mobile_partten.test(channel) ){
			make_rss_activate(channel,$(this))
		}else{
			$('input[name="contact"]').focus();
		}
	})

  //重新发送激活链接或激活码
	function re_generate_email_activate(obj,email){
		$.ajax({
			type: "POST",
			url: '/surveys/make_rss_activate',
			data: {rss_channel:email},
			beforeSend:function(){
				obj.next('span').remove();
				if(obj.next('span').length < 1){
					obj.after('<span ><img class="loading" src="/assets/image/sample/fancybox_loading@2x.gif" width="16" height="16" style="position:absolute;right:14px;top:8px;" /></span>')
				}				
			},
			success:function(retval){
				obj.next('span').remove();
				obj.after('<span ><img class="loading" src="/assets/od-quillme/success.png" width="16" height="16" style="position:absolute;right:14px;top:8px;" /></span>')
			}
		});		
	}

  //发送手机验证码或者邮箱激活链接
	function make_rss_activate(channel,button){
		$.ajax({
			type: "POST",
			url: '/surveys/make_rss_activate',
			data: {rss_channel:channel},
			beforeSend:function(){
				button.html('').append('<img style="margin-top:2px;" src="/assets/od-quillme/rss_loading.gif">').addClass('disabled')
			},
			success:function(retval){
					if(retval['success']){
						if(retval['new_user']){
							if(email_partten.test(channel)){
								var mail_host = channel.split('@')[1]
								var mail_to   = 'mail.' + mail_host
								//邮件订阅成功提示页
     							popup('#mail_success',channel,mail_to)
							}else{
                				popup('#mobile_success',channel,null)
							}

						}else{
							popup('#mobile_finish',null,null)	
						}
					}else{
						//订阅过程出错提示页
						popup('#rss_error',null,null)
					}
			}
		});		
	}


	//共用的弹出框函数
	function popup(obj,channel,mail_to){
    $.fancybox.open([
    		{href : obj}
    	],
			{
				beforeShow: function(){
      		$(".fancybox-skin").css({"backgroundColor":"#fff"});
      		if ($('span.mail').length > 0){
      			$('span.mail').text(channel)
      			$('button').attr('href',mail_to)	
      		}

      		if($('span.mobi').length > 0 ){
      			$('span.mobi').text(channel)
      		}

      		$('a.re_mail').next('span').remove();
      		$('a.re_mobile').next('span').remove();
      		
    		},
    		afterClose:function(){
    			$('a.rss-btn').html('订阅').removeClass('disabled')
    		},
    		width:500,
    		height:180,
    		scrolling:  'no'
			}
    );
	}

	//查询每种奖励类型的调研数量
	// function get_reward_type_count(status){
	// 	$.ajax({
	// 		type: "POST",
	// 		url: '/surveys/get_reward_type_count',
	// 		data: {status:status},
	// 		success:function(retval){
	// 			console.log(retval)
	// 			if(retval){
	// 				all_count  = 0;
	// 				cash_count = 0;
	// 				console.log(retval)
	// 				$.each(retval,function(index,value){
	// 					all_count += value
	// 					if(index == 1 || index == 2 || index == 16 ){
	// 						cash_count += value
	// 					}
	// 					if(index == 8){
	// 						$('span.c_t').text(value);
	// 					}
	// 					if(index == 0){
	// 						$('span.m_t').text(value);
	// 					}
	// 					if(index == 4){
	// 						$('span.u_t').text(value);
	// 					}	  				
	// 				})
	// 				$('span.all_t').text(all_count);
	// 				$('span.x_t').text(cash_count);
	
	// 				$('ul.reward_type li:first').find('span').text(all_count);
	// 			}else{
	// 				$('ul.reward_type li span').text(0)
	// 			}
	// 		}
	// 	});
	// }

	//ajax request 获取特定状态/类型的调研列表
	// function get_special_status_surveys(status,reward_type,page){
	// 	$.ajax({
	// 		type: "GET",
	// 		cache: true,
	// 		beforeSend:function(){
	// 			$('ul.list').children().remove()
	// 			if($('div.s_convert').length < 1){
	// 				$('<div class="s_convert"><img src="/assets/od-quillme/s_loading.gif"></div>').appendTo('ul.list')			
	// 			}
				
	// 		},
	// 		complete:function(){
	// 			$('div.s_convert').remove()
	// 		},
	// 		url: '/surveys/get_special_status_surveys',
	// 		data: {status:status,reward_type:reward_type,page:page}
	// 	});
	// }
});