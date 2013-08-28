//=require ui/widgets/od_address_selector
$(function(){
	var unit       = null;

	var partial_ul = null;
	var share_gift_point = null; //分享时用的积分
  var share_gift_title = null; //分享时的礼品名称


	$('.share_gift a').on('click',function(e){
		e.preventDefault;
		share_gift_point = (share_gift_point ? (share_gift_point) : window.point_value);
		share_gift_title = (share_gift_title ? (share_gift_title) : window.gift_name);		
		var s_uri =  window.location.protocol + "//" + window.location.host;
		$.social['shareTo' + $(this).attr('s_to')](s_uri, '我刚刚在问卷吧使用' + share_gift_point +  '积分兑换了' + share_gift_title + ',参与答题奖励多多,话费,现金,集分宝,积分换礼,快来参与吧 ! ^_^ [' + s_uri + '] ');
	})


	//账户中心下拉菜单
	$.form.powerfloat();


	function refresh_login_status(user){
		partial_ul = $('ul.login').clone();
		partial_ul.find('img.avatar').attr('src',user['avatar']);
		partial_ul.find('span.username').text(user['nickname']);
		partial_ul.find('i.integral').next('span').text(user['point'] + '积分');
		partial_ul.css('display','block')
		$('div.login_methods').children('ul').replaceWith(partial_ul)
		$.form.powerfloat();
	}

  //相应回车提交表单事件
  function submit_form(){
  	$('button.login_btn').click();
  }
  $('input[name="password"]').odEnter({enter: submit_form});


	//礼品排行切换
	$('.sh_type li').click(function(){
		$(this).siblings('li').removeClass('active').end().addClass('active')
		var sor_type = $(this).attr('type');
		$('.pagination a').attr('status',sor_type);
		$('.can_change').attr('sortype',sor_type);
		get_special_type_data(sor_type,null,null)
	})

	// 查看我能兑换的礼品
	$('.can_change').click(function(){
		var point = $(this).attr('point')
		var sort_type = $(this).attr('sortype')
		get_special_type_data(sort_type,null,point);
	})

	//订单类型的切换
	$('.exc_nav li').click(function(){
		var target_id = $(this).attr('class');
		$(this).siblings().removeClass('current').end().addClass('current');
		$('#'+ target_id ).siblings('div').hide().end().show();
		$('input').parent('div').removeClass('error')
		$('.number_notice').hide();
		$('.acc_notice').hide();
		if(target_id == 'jifen_exc' || target_id == 'qq_exc'){
			$('.ex_btn').children('b').text(0)	
		}else{
			$('.ex_btn').children('b').text(1000)	
		}
  		
  		$('span.select-txt').text('10元')		
	})

	//输入手机号后，判断是哪家运营商以及是否号码正确
	$('#phone_num').live('blur',function(){
		var custom_number = $(this).val();
		check_mobile_number($(this),custom_number,'bulr')
	})


	//输入框获得光标后错误提示消失
	$('input[name="custom_num"]').on('focus',function(){
		$('.number_notice').removeClass('err').hide();
		$('.acc_notice').removeClass('err').hide();
		$(this).parent('div').removeClass('error');
	})	

	var select  = $('div.select2')
	if (select.length > 0){
		$(select).toggle(function(){
			if($(this).children('ul').is(':visible')){
				$(this).parent('div').removeClass('active').end().children('ul').hide()
			}else{
				$(this).parent('div').addClass('active').end().children('ul').show()				
			}	
		},function(){
			if($(this).children('ul').is(':visible')){
				$(this).parent('div').removeClass('active').end().children('ul').hide()
			}else{
				$(this).parent('div').addClass('active').end().children('ul').show()				
			}	
		})
	}

  //下拉框选项点击事件
	$("body").click(function(e){
		var select = $(e.target).hasClass('select2') || $(e.target).parents('div').hasClass('select2')
		if(select && $(e.target).prop('tagName') != 'LI'){	
			$(e.target).closest('.select-content').parent('div').addClass('active').children('ul').show()	
		}else{
			$('.select-content').siblings('ul').hide()
			$('.select2').parent('div.active').removeClass('active')
		}
	})


  	$('.select-content').next('ul').children('li').click(function(){
  		if(!$(this).hasClass('bbrr')){
  			var ex_point = $(this).text()
  			$('.ex_btn').children('b').text(parseInt(ex_point) * 100)
  			$('span.select-txt').text(ex_point)  			
  		}
  	})


	$('input.v').on('blur keyup',function(){
		var num = $(this).val();
		num = parseInt(num)
		var order_type = $(this).closest('div').prev().find('input.account').attr('id')
		if(order_type == 'jifen_num'){
			if(isNaN(num)){
				$(this).parent('div').next('div').find('b').text(0)
			}else{
				$(this).parent('div').next('div').find('b').text(parseInt(num))
			}			
		}else{
			if(isNaN(num)){
				$(this).parent('div').next('div').find('b').text(0)
			}else{
				$(this).parent('div').next('div').find('b').text(parseInt(num) * 100 )		
			}
			
		}
	})

	//礼品列表页 立即兑换按钮点击事件
	$('.exc_detail div button').click(function(){
		var bt_class   = $(this).attr('class');
		var account    = $(this).parent().siblings().children('input.account');
		var order_type = account.attr('id');
		var value      = $(this).parent().siblings('div').find('span.select-txt');
		window.amount_value =  parseInt(value.text())		
		var point      = $(this).prev('span').find('b').text();
		if(point.length < 1){
			var point      = $(this).prev('b').text();
		}
		if (order_type !== 'phone_num' && order_type !== 'ali_num'){
			var value    = $(this).parent().siblings().children('input.v');
			window.amount_value        = value.val();
		}

		var account_v     = account.val();
		var custom_number = value.val();

		window.account_value       = account.val();
		window.order_type_value    = generate_order_type(order_type);
		window.exc_order_type      = order_type;
		window.point_value         = point;

		var go_on = jduge_order_type(account,value,order_type)

		if(go_on){
			if(bt_class == 'exc_login'){
				popup_login_page()
			}else if(bt_class == 'exc_right') {
				if(parseInt(window.total_point) >= parseInt(window.point_value)){
					popup_order_confirm_page()	
				}else{
					popup_point_less_page()
				}
							
			}
		}
	})


	//ajax  分页 获取gifts
	$('.pagination a').live('click',function(e){
			var status = $(this).attr('status');
			var page   = $(this).attr('page');	
			var point  = $(this).attr('point');
			get_special_type_data(status,page,point);
			return false;
	})


	//popup window  input elements focus 
	$('div.exc_notices  input').on('focus',function(){
		$(this).removeClass('error');
		$('div.err_notice').hide();
	})

	//弹出框内的登录按钮
	$('button.login_btn').on('click',function(){
		var username = $('input[name="username"]').val();
		var password = $('input[name="password"]').val();
		var remembr  = $('input[name="remember"]').attr('checked');
		var order_data = $('.order_data').attr('data');

		var thid_id  = null  //第三方 账户id
		if(username.length < 1 ){
			$('input[name="username"]').addClass('error')
		}else if(password.length < 1 ){
			$('input[name="password"]').addClass('error')
		}else{
			login($(this),username,password,thid_id,remembr,order_data)
		}
		
	})

	//关闭弹出框按钮
	$('input.close_f').on('click',function(){
		var redirect = $(this).attr('data');
		if(redirect){
			window.location.href = window.location.protocol + "//" + window.location.host + "/" + redirect;
		}else{
			$.fancybox.close();	
		}
		
	})

	//点击分享给好友按钮
	$('input.look_over').on('click',function(){
		$(this).parent('div.answer_look').siblings('.share_gift').show();
	})

	$('input.order_confirm').on('click',function(){
		var spans = $(this).parent('div').prev('div').find('span.order_common');
		var order_data = {}
		var options    = {}
		spans.each(function(){
			name = $(this).attr('name')
			order_data[name] = $(this).attr('data');
		})
				
		generate_orders($(this),order_data)
	})



	//获取当前页面地址
	function current_page(){
		return window.location.href.split('/').pop();
	}

	
	function popup_login_page(){
		popup('#gift_login')
	}

	function popup_point_less_page(){
		var current_p =  current_page();
		if(current_p == 'gifts'){
			popup("#point_less")
		}else{
			popup("#point_less",'surveys','gifts')
		}

	}

	function popup_order_confirm_page(){
		popup("#feedm_confirm")
	}

	function popup_order_ok_page(){
		var current_p =  current_page();
		var order_ok  = null;		
		if(current_p == 'gifts'){
			popup("#order_ok")
			window.amount_value + unit
			order_ok = '<div class="o_t">系统审核通过后我们会把' + window.amount_value + unit + '充值到您的账户</div>'
		}else{
			popup("#order_ok",'surveys','gifts')

			order_ok = '<div class="o_t">系统会在审核通过后将礼品寄送到您的收货地址</div>'
		}

		$('div.order_details').prepend(order_ok);
		
	}

	function popup_address_page(){
		//获取收获地址
		popup("#recever")
		get_recerver_info()
	}

	function popup_address_confirm_page(){
		if($('input[name="info_sys"]').attr('checked') == 'checked'){
			window.info_sys        =  true
		}else{
			window.info_sys        =  false
		}
		
		window.sample_receiver = $('input[name="receiver"]').val()
		window.sample_mobile   = $('input[name="mobile"]').val()
		window.sample_postcode = $('input[name="postcode"]').val()
		window.sample_address  = window.addressSelector.odAddressSelector('val')['address']
		window.sample_street_info = $('textarea[name="street_info"]').val() 
		window.sample_real_address = $('select.address-province option:selected').text() + ' ' + $('select.address-city option:selected').text() + ' ' + $('select.address-town option:selected').text()
		popup("#recever_confirm")	
	}

	//用来判断当前兑换类型
	function jduge_order_type(account,value,order_type){
		switch (order_type){
			case 'phone_num':
				go_on = check_mobile_number(account,'click')
				break;
			default:
				go_on = validate_number(account,value,order_type)
				break;
		}	
		return go_on
	}

			
	function generate_order_type(o_type){
		var t = ''
		switch(o_type){
			case 'phone_num':
				t = '话费兑换'
				break;
			case 'ali_num':
				t = '现金兑换'
				break;
			case 'jifen_num':
				t = '集分宝兑换'
				break;
			case 'qq_num':
				t = 'Q币兑换'
				break;
		}
		return t
	}


	//按照指定的排序规则查找gifts
	function get_special_type_data(sor_type,p,point){
		$.ajax({
			type: "get",
			url: '/gifts/get_special_type_data',
			data: {status:sor_type,page:p,point:point}
		});
	}


	//验证输入的数字是否符合要求
	function validate_number(account,value,order_type){
		var acc     = account.val();	
		var number  = window.amount_value		
		var num_reg = /^[1-9]\d*$/
		var go_on   = false
		switch (order_type){
			case 'ali_num':
				if(($.regex.isMobile(acc) || $.regex.isEmail(acc)) && (number >= 10 && num_reg.test(number))){
					go_on = true
				}else{
					if(!$.regex.isMobile(acc) && !$.regex.isEmail(acc)){
						account.parent('div').addClass('error')
						$('.acc_notice').addClass('err').text('请输入手机或邮箱').show();
					}
				}			
				break;
			case 'qq_num':
				if($.regex.isQq(acc) && num_reg.test(number)){
					go_on = true
				}else{
					if(!$.regex.isQq(acc)){
						account.parent('div').addClass('error')
						$('.acc_notice').addClass('err').text('请输入正确信息').show();
					}else{
						value.parent('div').addClass('error');
						$('.number_notice').addClass('err').text('请输入0元以上整数').show();						
					}
				}
				break;	
			default:
				if(acc.length > 0 && num_reg.test(number)){
					go_on = true
				}else{
					if(acc.length < 1){
						account.parent('div').addClass('error')
						$('.acc_notice').addClass('err').text('请输入账户信息').show();
					}else{
						value.parent('div').addClass('error');
						$('.number_notice').addClass('err').text('请输入0元以上整数').show();						
					}
				}
				break;
		}
		return go_on	
	}


	//  验证手机号码   
	function check_mobile_number(obj,event_type){
		var number = obj.val();
		var number_ok = true
		if($.regex.isYidongNumber(number)){
			$('.acc_notice').text('中国移动').show();
		}else if($.regex.isDianxinNumber(number)){
			$('.acc_notice').text('中国电信').show();
		}else if($.regex.isLianTongNumber(number)){
			$('.acc_notice').text('中国联通').show();
		}else{
			if(event_type == 'click'){
				obj.parent('div').addClass('error');
				$('.acc_notice').addClass('err').text('号码错误').show();
				number_ok = false;				
			}

		}
		return number_ok;
	}


	//共用的弹出框函数
	function popup(obj,redirect,another_redirect){
		$.fancybox.open([
				{href : obj}
			],
			{
				beforeShow: function(){
					//$.form.placeholder();
					$(".fancybox-skin").css({"backgroundColor":"#fff"}); 

					if(redirect){
						$(obj).find('input.answer').attr('data',redirect)	
					}
					if(another_redirect){
						$(obj).find('input.look_over').attr('data',another_redirect)	
					}
					
					if($('input.answer').length > 0 && redirect){
						$('input.answer').attr('data',redirect)
					}

					if($('input.look_over').length > 0 && another_redirect){
						$('input.look_over').attr('data',another_redirect)
					}          
					//传递数据到popup窗口
					fill_order_confirm_data(obj)
															
				},
				afterClose:function(){
					$('.order_details').children('div.o_t').remove()
				},
				width:500,
				padding:10,
				scrolling:  'no'
			}
		);
	}

	function fill_order_confirm_data(obj){
		//充值订单确认页
		var o_username = $('span.o_username');
		var o_type     = $('span.o_type');
		var o_target   = $('span.o_target');
		var o_amount   = $('span.o_amount');
		var o_point    = $('span.o_point');
		var o_ramain_point = $('span.o_remain_point');
		var unenough   = $('span.unenough');
		

		switch (window.order_type_value){
			case '话费兑换':
				unit = '元话费'
				break;
			case '现金兑换':
				unit = '元现金'
				break;	
			case '集分宝兑换':
				unit = '集分宝'
				break;	
			case 'Q币兑换':
				unit = 'Q币'
				break;	
		}


		share_gift_title =   window.amount_value + unit ;
		share_gift_point =   window.point_value ; 


		if(o_username.length > 0 ){
			o_username.text(window.username);
		}
		if(o_type.length > 0){
			o_type.attr('data',window.exc_order_type);
			o_type.text(window.order_type_value);
		}   
		if(o_target.length > 0){
			o_target.attr('data',window.account_value);
			o_target.text(window.account_value);
		}     
		if(o_point.length > 0){
			o_point.attr('data',window.point_value);
			o_point.text(window.point_value);
		} 
		if(o_ramain_point.length > 0){
			o_ramain_point.text(parseInt(window.total_point) - parseInt(window.point_value));
		} 
		if(o_amount.length > 0){
			o_amount.attr('data',window.amount_value);
			o_amount.text(window.amount_value + unit);
		}	

		//积分不足页面
		if(unenough.length > 0){
			unenough.text(window.total_point);
		} 

		//确认地址信息
		$('span[name="receiver"]').attr('data',window.sample_receiver).text(window.sample_receiver)
		$('span[name="mobile"]').attr('data',window.sample_mobile).text(window.sample_mobile)
		$('span[name="postcode"]').attr('data',window.sample_postcode).text(window.sample_postcode)
		$('span[name="address"]').attr('data',window.sample_address).text(window.sample_real_address)
		$('span[name="info_sys"]').attr('data',window.info_sys)
		$('span[name="street_info"]').attr('data',window.sample_street_info).text(window.sample_street_info)
	}

	function login(obj,account,pass,thid_id,signed_in,order_data){
			obj.attr('disabled',true).addClass('disabled').html('登录中');
			$.postJSON('/account/login.json',{email_mobile:account,password:pass,third_party_user_id:thid_id,permanent_signed_in:signed_in},function(retval){
				if(retval.success){
					$('button.exc_login').removeClass('exc_login').addClass('exc_right');
					if($('button.reedm_right_now').hasClass('not_login')){
						$('button').removeClass('not_login');
					}
					get_user_basic_info(retval.value['auth_key']);
				}else{
					obj.html('登录').attr('disabled',false).removeClass('disabled');
					jduge_error_type(retval.value['error_code']);
				}
			})  	
	}


	function get_user_basic_info(authkey){
		$.postJSON('/account/get_basic_info_by_auth_key.json',{auth_key:authkey},function(retval){
			if(retval.success){       	
				refresh_login_status(retval.value)
				window.username = retval.value['nickname']  
				window.total_point    = retval.value['point']			
				can_freedm = parseInt(window.total_point) - parseInt(window.point_value) 
				if (can_freedm >= 0  ){
					current_p =  current_page();
					if(current_p == 'gifts'){
						popup_order_confirm_page()
					}else{
						popup_address_page()
					}         	
				}else{
					popup_point_less_page()
				}
					
			}
		})
	} 

	//获取收获地址
	function get_recerver_info(){
		if(typeof(window.sample_receiver) != 'undefined'){
				$('input[name="receiver"]').val(window.sample_receiver)
				$('input[name="mobile"]').val(window.sample_mobile)
				$('input[name="postcode"]').val(window.sample_postcode)
				$('textarea[name="street_info"]').val(window.sample_street_info)
				generate_address(window.sample_address)
			}else{
				$.getJSON('/users/setting/address.json',{},function(retval){
						window.sample_receiver = retval.value.receiver; 
						window.sample_mobile   = retval.value.mobile; 
						window.sample_postcode = retval.value.postcode;
						window.sample_address  = retval.value.address;
						window.sample_street_info = retval.value.street_info;
						$('input[name="receiver"]').val(window.sample_receiver);
						$('input[name="mobile"]').val(window.sample_mobile);
						$('input[name="postcode"]').val(window.sample_postcode);
						$('textarea[name="street_info"]').val(window.sample_street_info);
						generate_address(window.sample_address);			
				}) 
			}
	}



	function generate_address(address_code){
		if($('div.address-slt').length < 1){
			window.addressSelector = $.od.odAddressSelector({ precision: 2, // 0. province, 1. city, 2. town, 3. detail 
			has_postcode: false, 
			value: { address: address_code, 
								detail: '', postcode: '' 
							} 
			}).appendTo('#recerver_address');
		}
	}

	//
	function generate_orders(button,order_obj){
		button.val('兑换中......').attr('disabled',true).addClass('disabled');
		button.prev('input.answer').attr('disabled',true).addClass('disabled');
		var alink = button.siblings('a');
		if(alink.length > 0){
			alink.bind('click', false);
		}
		$.postJSON('/orders.json',{order:order_obj},function(retval){
			if(retval.success){
				window.total_point =  window.total_point  - parseInt(order_obj['point'])
				button.val('继续提交') 
				button.attr('disabled',false).removeClass('disabled');
				button.prev('input.answer').attr('disabled',false).removeClass('disabled');
				if(alink.length > 0){
					alink.unbind('click', false);
				}				
				popup_order_ok_page();
			}else{
				console.log(retval)
			}
		})
	}


	function jduge_error_type(error_type){
		var err_notice = null
		var top_n = '115px'
		switch(error_type){
			case 'error_3':
					err_notice = "<i></i><span>账户未激活,您可以<a href='/account/sign_up'>重新激活</a></span>"
				break;
			case 'error_4':
				err_notice = "<i></i><span>账户不存在 ,您可以<a href='/account/sign_up'>注册</a></span>"
				break;
			case 'error_11':
			top_n = '185px'
				err_notice = "<i></i><span>密码错误</span>"
				break;
			case 'error_24':
				err_notice = "<i></i><span>账户未激活,您可以<a href='/account/sign_up'>重新激活</a></span>"
				break;
		}
		$('.err_notice').html(err_notice).show().css("top",top_n);
	}


	//gift show page 

	//立即兑换
	$('button.reedm_right_now').click(function(){
		if($(this).hasClass('not_login')){
			popup_login_page()
		}else{
			if(parseInt(window.total_point) >= parseInt(window.point_value)){
				popup_address_page()
			}else{
				popup_point_less_page()
			}
			
		}
	})


	$('.address-province').live('change',function(){
		$('span.notice').hide()	
	})


	$('input.sub_btn').on('click',function(){
		if($(this).hasClass('con_sub_btn')){
			var order_data = {}
			$('div.sub_infor').find('span.recerver_info').each(function(){
				var name = $(this).attr('name')
				order_data[name] = $(this).attr('data')
			})
			order_data['point'] = window.point_value
			order_data['gift_id'] = window.gift_id
			order_data['amount']  = 1
			generate_orders($(this),order_data)
		}else{
			var go_on = check_enter()
			if(go_on){
				popup_address_confirm_page()	
			}
			
		}
	})


	function check_enter(){
		var receiver 	= $('input[name="receiver"]').val()
		var mobile   	= $('input[name="mobile"]').val()
		var postcode 	= $('input[name="postcode"]').val()
		var province 	= $('select.address-province').val()
		var city     	= $('select.address-city').val()
		var town     	= $('select.address-town').val()
		var street_info = $('textarea[name="street_info"]').val()

		var go = false
		if(!$.regex.isReceiver(receiver) || $.regex.isDefaultReceiver(receiver)){
			$('input[name="receiver"]').addClass('error')
		}else if(!$.regex.isMobile(mobile)){
			$('input[name="mobile"]').addClass('error')
		}else if(!$.regex.isPostcode(postcode)){
			$('input[name="postcode"]').addClass('error')
		}else if(province < 0 || city < 0 || town < 0){
			$('span.notice').show()	
		}else if(street_info.length < 1 || $.regex.isStreet(street_info)){
			$('textarea').addClass('error')
		} else{
			$('span.notice').hide()	
			go = true
		}

		return go
				
	}


	$('a.repair_address').on('click',function(){
		popup_address_page();
	})


})
