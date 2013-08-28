//=require jquery.placeholder
//=require jquery.cookie
jQuery(function($) {

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

  //相应回车提交表单事件
  function commit_rss(){
  	$('.rss-btn').click();
  }
  $('input[name="contact"]').odEnter({enter: commit_rss});	

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
						butt.next('.code_exp').show();
					}
					
				}
			})
		}else{
			$('input[name="code"]').focus();
		}

	})

	$('input[name="code"]').focus(function(){
		$('button.next_f').next('.code_exp').hide();
	});

  //订阅按钮
	$('input[name="contact"]').next('a').click(function(){
		var channel = $('input[name="contact"]').val();
		if($.regex.isEmail(channel) || $.regex.isMobile(channel) ){
			make_rss_activate(channel,$(this))
		}else{
			$('input[name="contact"]').prev('.channel_err').show();
		}
	})

	$('input[name="contact"]').focus(function(){
		$(this).prev('.channel_err').hide();
	})


  //重新发送激活链接或激活码
	function re_generate_email_activate(obj,email){
		$.ajax({
			type: "POST",
			url: '/surveys/make_rss_activate',
			data: {rss_channel:email},
			
			beforeSend:function(){
				obj.next('img').remove();
				if(obj.next('img').length < 1){
					if($.regex.isEmail(email)){
						obj.after('<img class="loading" src="/assets/image/sample/fancybox_loading@2x.gif" width="16" height="16" style="position:absolute;left:64px;top:44px;" />')
					}else{
						obj.after('<img class="loading" src="/assets/image/sample/fancybox_loading@2x.gif" width="16" height="16" style="position:absolute;right:50px;top:8px;" />')
					}
					
				}				
			},
			success:function(retval){
				obj.next('img').remove();
				if($.regex.isEmail(email)){
					obj.after('<img class="loading" src="/assets/od-quillme/success.png" width="16" height="16" style="position:absolute;left:64px;top:44px;" />')
				}else{
					obj.after('<img class="loading" src="/assets/od-quillme/success.png" width="16" height="16" style="position:absolute;rigt:50px;top:9px;" />')
				}				
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
							if($.regex.isEmail(channel)){
        						if(channel.indexOf('gmail.com') > -1){
        						  var mail_to = 'http://gmail.com';
        						}else if(channel.indexOf('@tencent.') > -1){
        						  var mail_to = 'http://mail.qq.com';
        						}else if(channel.indexOf('@qq.') > -1){
        						  var mail_to = 'http://mail.qq.com';
        						}else{
        						  var mail_to = 'http://mail.'  + channel.split('@')[1];
        						}
								//邮件订阅成功提示页
     							popup('#mail_success',channel,mail_to)
							}else{
                				popup('#mobile_success',channel,null)
							}

						}else{
							if($.regex.isEmail(channel)){
								popup('#email_finish',null,null)
							}else{
								popup('#mobile_finish',null,null)	
							}
								
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
    			$('a.rss-btn').html('订阅').removeClass('disabled');
    			$('input[name="code"]').val('');
    			$('.code_exp').hide();
    		},
    		width:500,
    		height:180,
    		scrolling:  'no'
			}
    );
	}
});