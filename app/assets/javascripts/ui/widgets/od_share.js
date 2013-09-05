//=require ./_base
//=require jquery.fancybox.pack
//=require jquery.zclip
//=require utility/social
//=require ui/plugins/od_button_text
//=require jquery-powerFloat-min
//=require utility/form
//=require ui/plugins/od_enter
//=require ./_templates/od_share
(function($){
	var page = '';
	var href = '';
	$.odWidget("odShare", {
		options: { 
    	point:null,
    	survey_title:null,
    	scheme_id:null,
    	images:null
    },
  
  	_popup_page:function(){
  		if(parseInt(this.options.point) > 0 &&  typeof(window.current_user_id) == 'undefined' ){
  			page = '#share_survey'
  		}else{
  			page = '#s_survey'
  		}
  	},

  	_share_social:function(option){
			$.each(['SinaWeibo', 'TencentWeibo', 'Renren', 'Douban', 'QQSpace', 
				'Kaixin001', 'Diandian', 'Gmail', 'Fetion'], function(index,v) {
				$('a.' + v).click(function() {
					var s_imgs = null;
					if(option.images){
						switch(v){
						case 'SinaWeibo':
							var s_imgs =   option.images.replaceAll(',','||');
							break;
						case 'TencentWeibo':
							var s_imgs =  option.images.replaceAll(',','|');
							break;
						case 'Renren':
							var s_imgs = option.images.replaceAll(',','||');
							break;
						case 'Douban':
							var s_imgs = option.images.replaceAll(',','||');
							break;			
						}			
					}
					$.social['shareTo' + v](href, '问卷吧邀您参加:'+ option.survey_title + ',我们非常希望能得到您的宝贵意见',s_imgs);
				});
			});  		
  	},

  	_handle_login:function(){
  		$('button.share_s_btn').click();
  	},

  	_login:function(){
  		//相应回车提交表单事件 
  		$('input[name="password"]').odEnter({enter: $pop._handle_login})

			$('input[name="username"]').focus(function(){
				$(this).removeClass('error');
				$('.acc').hide();
			})
			$('input[name="password"]').focus(function(){
				$(this).removeClass('error');
				$('.pas').hide();
			})
		
  		var ele = $pop.hbs($pop.options);
			$('.share_s_btn').on('click',function(){
				var uname = $('input#username').val();
				var passw = $('input#password').val();
				var remeb = $('input[name="remember"]').attr('checked');
			
				if(uname.length  < 1){
					$('input#username').addClass('error');
				}else if (passw.length < 1){
					$('input#password').addClass('error');
				}else{
						$pop._share_login($(this),uname,passw,null,remeb);
				}
			})
  	},

  	_share_login:function(obj,account,pass,thid_id,signed_in){
  		obj.odButtonText({ text: '登录中...'}).attr('disabled',true).addClass('disabled');
				var reward_point = obj.parents('.share_l').find('.share_point').text()
				$.postJSON('/account/login.json',{email_mobile:account,password:pass,third_party_user_id:thid_id,permanent_signed_in:signed_in},function(retval){
					if(retval.success){
						$pop._get_user_basic_info(retval.value['auth_key'],reward_point);
					}else{
						obj.odButtonText('restore').attr('disabled',false).removeClass('disabled');
						$pop._jduge_error_type(retval.value['error_code'])
					}
				})  
  	},

  	_jduge_error_type:function (error_type){
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
		},

		_refresh_login_status:function(user){
			partial_ul = $('ul.login').clone();
			partial_ul.find('img.avatar').attr('src',user['avatar']);
			partial_ul.find('span.username').text(user['nickname']);
			partial_ul.find('i.integral').next('span').text(user['point'] + '积分');
			partial_ul.css('display','block')
			$('div.login_methods').children('ul').replaceWith(partial_ul)
			$.form.powerfloat();
		},

		_get_user_basic_info:function(authkey,reward_point){
			$.postJSON('/account/get_basic_info_by_auth_key.json',{auth_key:authkey},function(retval){
				if(retval.success){
					$pop._refresh_login_status(retval.value)  
					window.current_user_id = retval.value['sample_id'];
					var page = '#s_survey';
					$pop._create();		
				}
			})
		},


		_create:function(){
			$pop    = this;
			$pop._popup_page();
			var ele =		$pop.hbs($pop.options);
			var opt = 	$pop.options;
			var url_input = ele.find(page).find('.share_url');
			var copy_button = url_input.next('button')
			$.fancybox(
				ele.find(page),
				{
					beforeShow: function(){
						$(".fancybox-skin").css({"backgroundColor":"#fff"});
						url_input.mouseover(function(e) { $(e.target).select(); });	
						var share_url =  window.location.protocol + "//"  + window.location.host + '/s/' + opt.scheme_id		
						if(typeof(window.current_user_id) != 'undefined'){
							var share_url =  share_url  + '?i=' + window.current_user_id;  
							if(parseInt(opt.point) > 0){
								$('.p_num').html(opt.point);
								$('.share_tit').show();
								$('.share_cont').css("height",'250px');
							}else{
								$('.share_cont').css("height",'220px');
							}
						}
						href = share_url;
						url_input.val(share_url);
					},
					afterShow:function(){
						url_input.select();
						$pop._share_social(opt);
						copy_button.zclip({
							path:'/assets/ZeroClipboard.swf',
							copy:href,
							beforeCopy:function(){
								//something can be do 
							},
							afterCopy:function(){
								if($(this).next('div.share-notice:visible').length < 1){
									$(this).next('div.share-notice').show()	
								}
							}
						});		

						if(page == '#share_survey'){
							$pop._login()
						}

					},
					scrolling:  'no',  
					padding : 8,
					width:510,
					height:230  
				}
			)
		}

	})
})(jQuery)