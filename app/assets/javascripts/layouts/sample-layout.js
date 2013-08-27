//=require jquery.fancybox.pack
//=require jQuery.blockUI
//=require jquery.SuperSlide
//=require utility/ajax
//=require jquery.zclip
//=require jquery.highlight
//=require jquery-powerFloat-min
//=require utility/social
//=require utility/od_form


$(document).ready(function(){
	var partial_ul = null;

	$.powerfloat();

	function refresh_login_status(user){
		partial_ul = $('ul.login').clone();
		partial_ul.find('img.avatar').attr('src',user['avatar']);
		partial_ul.find('span.username').text(user['nickname']);
		partial_ul.find('i.integral').next('span').text(user['point'] + '积分');
		partial_ul.css('display','block')
		$('div.login_methods').children('ul').replaceWith(partial_ul)
		$.powerfloat();
	}
	


	jQuery(".slider").slide( { mainCell:".bd ul",effect:"leftLoop",autoPlay:true} );

	$.each(['SinaWeibo', 'TencentWeibo', 'Renren', 'Douban', 'QQSpace', 
		'Kaixin001', 'Diandian', 'Gmail', 'Fetion'], function(index,v) {	
		$('a.' + v).click(function() {
			$.social['shareTo' + v](share_url, '问卷吧邀您参加:'+ survey_title + ',我们非常希望能得到您的宝贵意见');
		});
	});





  //相应回车提交表单事件
  $.enterSubmit($('button.share_s_btn'))

  // placeholder for IE 
  $.placeholder();

  var prizes_container = null
	$('.unfold-btn').on('click',function(){
		var ico = $(this).children('i')
		var open  = null
		if(ico.hasClass('open')){
			open = true  
		}else{
			open = false
		}
			
		var link = $(this);
		if(open){
			ico.replaceWith("<img class='pr_loading' src='/assets/od-quillme/icons/loading.gif' style='vertical-align:middle;width:16px;height:14px;margiin:-2px 2px 0 0'>")
			var prize_ids = $(this).attr('data');
			var survey_id = $(this).attr('survey_id');
			var scheme_id = $(this).attr('scheme_id');
			prizes_container = $(this).parents('span.research-meta').siblings('ul.reward_list');
			// ajax request
			$.postJSON('/prizes/find_by_ids.json',{ids:prize_ids},function(retval){
				if(retval.success){
					link.children('i').removeClass('open').addClass('close').next('span').html('收起');          	
					$(".loading").remove();
					link.parents('.research-meta').siblings('.reward_list').show();
					$.each(retval.value,function(index){
						var priz_index = 'priz' + index
						var tmp = '<li id="'+ survey_id + this._id +'">\
							<a href="#' + this._id + survey_id + '" class="pop" rel="survey_' + survey_id + prize_ids + 'data="'+ this._id +'" index="'+ index +'" >\
								<img src=" ' + this.photo_src + ' " alt="">\
								<span class="gift-mask"></span>\
								<div class="gift-name">\
									<div>' + this.title +   '</div>\
								</div></a></li>'
							if($('#'+survey_id+this._id).length < 1){
								$(tmp).appendTo(prizes_container)	
							}
								
						var popup = '<div id="' + this._id + survey_id + '" style="display:none;" class="pri1"> \
							<div class="prize_info"> \
								<div class="detail"> \
									<div class="title">参与本次调研就有机会获得如下奖品</div> \
										<div class="prize_img"> \
											<img src="' + this.photo_src + '"/> \
										</div> \
									<div class="prize_intro"> \
									<p class="prize_title">' +  this.title + '</p> \
									<p class="prize_price">市场价: <span class="price_info">￥' + this.price + '</span></p> \
									<p> \
										<span class="p_intro">奖品介绍 :</span><br/> \
										<span class="intro_info">' + this.description + '</span>  \
									</p> \
									<a class="prize_btn" href="/s/'+scheme_id+'" target="_blank">立即参与</a>\
								</div> \
								<div style="clear:both;"></div> \
								<div class="slide_nav"> '
						var lis = ''
						$.each(prize_ids.split(','),function(i){
							lis += '<li class="slide"></li>'  
						})
						var popup_1 = '</div></div></div></div>'
						$(popup + lis + popup_1 ).appendTo(prizes_container)
					})
					$('img.pr_loading').replaceWith('<i class="icon16 close"></i>')
					$('i.close').next('span').html('收起');
				}else{
					console.log(retval.value)      
				}
			})
		}else{
			$(this).parents('.research-meta').siblings('.reward_list').hide();
			$(this).children('i').removeClass('close').addClass('open').next('span').html('展开');
			prizes_container.html('');
		}
	})


	$(".pop").fancybox({
		beforeShow: function(){
			$(".fancybox-skin").css({"backgroundColor":"#fff"});
			var target_id = $(this.element).attr('href');
			var slides =  $("div" + target_id ).find('.slide');  
			slides.removeClass('current_slide');
			$(slides[this.index]).addClass('current_slide')
			if(this.index == 0) {
				$(this.tpl.prev).appendTo($.fancybox.outer).css({"opacity":0.6});
				$('.fancybox-prev').children('span').css({"background":"url(/assets/image/sample/prev_e.jpg)","background-repeat":"no-repeat"})
			} else if( this.index < this.group.length){
				$(this.tpl.next).appendTo($.fancybox.outer).css({"opacity":0.6});
				$(".fancybox-next").children('span').css({"background":"url(/assets/image/sample/next_e.jpg)","background-repeat":"no-repeat"})
			}    
		},
		afterShow: function(){
			var target_id = $(this.element).attr('href');  
			var slides =  $("div" + target_id ).find('.slide');  
			slides.removeClass('current_slide');
			$(slides[this.index]).addClass('current_slide')
		},
		autoPlay: false,
		nextEffect: 'none',
		prevEffect: 'none',				
		width:654,
		height:362,
		scrolling:  'no',
		padding : [20, 28, 20, 28],
		closeBtn: true,
		arrows:true,
		loop:false
	});


	var copy_button = null;
	var share_url = null;
	var survey_title = null;
	var share_pic = null;
	$('.share-btn').fancybox({
		
		beforeShow: function(){
			$(".fancybox-skin").css({"backgroundColor":"#fff"});
			var point 		 = $(this.element).attr('data');
			var survey_id 	 = $(this.element).attr('survey_id');
			var scheme_id 	 = $(this.element).attr('scheme_id');
			survey_title = $(this.element).attr('s_title')
			copy_button = 'c_survey'
			if(typeof(window.current_user_id) == 'undefined'){
				share_url =  window.location.protocol + '//' + window.location.hostname + '/s/' + scheme_id
				if(parseInt(point) > 0){
					copy_button = 'copy_survey'
					$('.share_point').text(point)	
					$("#share_survey").find('.share_url').val(share_url);
					var href = $('#survey_url').val();
					var href_ipt = $('#survey_url').mouseover(function(e) { $(e.target).select(); });
				}else{
					$("#s_survey").find('.share_url').val(share_url);
					var href = $('#s_url').val();
				}
			}else{
				if(parseInt(point) > 0){
					$('.share_tit').show()
					$("#s_survey").find('.p_num').html(point);	
					$('#s_survey').find('.share_cont').css("height",'250px');
				}else{
					$('#s_survey').find('.share_cont').css("height",'220px');
				}
				share_url =  window.location.protocol + '//' + window.location.hostname + '/s/' + scheme_id + '?i=' + window.current_user_id
				$("#s_survey").find('.share_url').val(share_url);  
				var href = $('#s_url').val();      
			}

			if(typeof(href_ipt) == 'undefined'){
				var href_ipt = $('#s_url').mouseover(function(e) { $(e.target).select(); });	
			}
		},
		afterShow:function(){
			$('#survey_url').select();
			$('#s_url').select();
			$("#"+copy_button).zclip({
				path:'/assets/ZeroClipboard.swf',
				copy:share_url,
				beforeCopy:function(){
					//something can be do 
				},
				afterCopy:function(){
					if($(this).next('div.share-notice:visible').length < 1){
						$(this).next('div.share-notice').show()	
					}
				}
			});
		},
		afterClose: function(){
			$('span.red').remove();
			$('span.green').remove();
			$('.share_tit').hide();
			$('.err_notice').hide();
			$("#"+copy_button).next('div.share-notice').hide()  
		},   
		scrolling:  'no',  
		padding : 8,
		width:510,
		height:230        
	}) 


	$('input[name="username"]').focus(function(){
		$('.acc').hide()
	})
	$('input[name="password"]').focus(function(){
		$('.pas').hide()
	})

	$('.share_s_btn').on('click',function(){
		var uname = $('input#username').val();
		var passw = $('input#password').val();
		
		var remeb = $('input[name="remember"]').attr('checked');
		if(uname.length  < 1){
			$('input#username').addClass('error');
		}else if (passw.length < 1){
			$('input#password').addClass('error');
		}else{
				share_login($(this),uname,passw,null,remeb);
		}
	})

	function share_login(obj,account,pass,thid_id,signed_in){
		obj.html('登录中...').attr('disabled',true).addClass('disabled');
		var reward_point = obj.parents('.share_l').find('.share_point').text()
		$.postJSON('/account/login.json',{email_mobile:account,password:pass,third_party_user_id:thid_id,permanent_signed_in:signed_in},function(retval){
			if(retval.success){
				get_user_basic_info(retval.value['auth_key'],reward_point)
			}else{
				obj.html('<span>登</span>录').attr('disabled',false).removeClass('disabled')
				jduge_error_type(retval.value['error_code'])
			}
		})  
	}


	function jduge_error_type(error_type){
		var top_var = "28px"
		var err_notice = null
		switch(error_type){
			case 'error_3':
					err_notice = "<i></i><span>账户未激活,您可以<a href='/account/sign_up'>重新激活</a></span>"
				break;
			case 'error_4':
				err_notice = "<i></i><span>账户不存在 ,您可以<a href='/account/sign_up'>注册</a></span>"
				break;
			case 'error_11':
				err_notice = "<i></i><span>密码错误</span>"
				top_var = "78px"
				break;
			case 'error_24':
				err_notice = "<i></i><span>账户未激活,您可以<a href='/account/sign_up'>重新激活</a></span>"
				break;
		}
		if(top_var == '28px'){
			$('.err_notice').removeClass('pas').addClass('acc')
		}else{
			$('.err_notice').removeClass('acc').addClass('pas')
		}
		$('.err_notice').html(err_notice).show().css({"top":top_var});
	}



	function get_user_basic_info(authkey,reward_point){
		$.postJSON('/account/get_basic_info_by_auth_key.json',{auth_key:authkey},function(retval){
			if(retval.success){
				refresh_login_status(retval.value)  
				window.current_user_id = retval.value['sample_id'];
				popup('#s_survey');
				$('#s_survey').find('.share_cont').css("height",'250px');	
				$('#s_survey').find('.p_num').text(reward_point);
				$('#s_survey').find('.share_tit').show();
				$('a.share-btn').attr('href','#s_survey');
				$('#s_url').select();
				$("#c_survey").zclip({
					path:'/assets/ZeroClipboard.swf',
					copy:share_url,
					beforeCopy:function(){
						//something can be do 
					},
					afterCopy:function(){
						if($(this).next('div.share-notice:visible').length < 1){
							$(this).next('div.share-notice').show()	
						}
					}
				});				

			}
		})
	}




	function popup(obj){
		$.fancybox.open([
				{href : obj}
			],
			{
				beforeShow: function(){
					$(".fancybox-skin").css({"backgroundColor":"#fff"});
					var point = $('#share_survey').find('span.p_num').text();

					var scheme_id = $('#survey_url').val().split('/s/')[1]
					$("#s_survey").find('.p_num').html(point);

					share_url =  window.location.origin + '/s/' + scheme_id + '?i=' + window.current_user_id
					$("#s_survey").find('.share_url').val(share_url);        
		
					
					var href = $('#survey_url').val();
					var href_ipt = $('#survey_url').mouseover(function(e) { $(e.target).select(); });															
				},
				afterClose: function(){
					$('#s_survey').find('.share_cont').css("height",'220px');
					$('#s_survey').find('.share_tit').hide();
					$('#s_survey').find('.share-notice').hide();
						
				},   
				scrolling:  'no',  
				padding : 8,
				width:510,
				height:230  
			}
		);
	}
})