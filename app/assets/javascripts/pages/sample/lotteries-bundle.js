//=require ui/widgets/od_progressbar
//=require ui/widgets/od_address_selector
$(function(){

	var postcode_reg    = $.postcode_reg();
	var receiver_reg  = $.receiver_reg();
	var default_receiver = $.default_receiver();	
	var street_info_partten = $.street_info_partten();
	var mobile_partten = $.mobile_partten();



	$('div.dashed-top-tit li').click(function(){
		$(this).addClass('current').siblings('li').removeClass('current')
		if($(this).hasClass('fail_log')){
			$('ul.fail_log').show().siblings('ul').hide()
		}else{
			$('ul.succ_log').show().siblings('ul').hide();
		}
	})

	$(".sidebar-box").addClass("has-slot");
	 var pb = $.od.odProgressbar({color: "#6D91A9", width: 400, value: 0});
	 pb.appendTo('#od_pb');

	var sources = [
		"/assets/image/quillme/slotMachine/fly1.png",
		"/assets/image/quillme/slotMachine/fly2.png",
		"/assets/image/quillme/slotMachine/fly3.png",
		"/assets/image/quillme/slotMachine/fly4.png",
		"/assets/image/quillme/slotMachine/fly5.png",
		"/assets/image/quillme/slotMachine/fly6.png",
		"/assets/image/quillme/slotMachine/fly7.png",
		"/assets/image/quillme/slotMachine/fly8.png",
		"/assets/image/quillme/slotMachine/fly9.png",
		"/assets/image/quillme/slotMachine/fly10.png",
		"/assets/image/quillme/slotMachine/fly11.png",
		"/assets/image/quillme/slotMachine/fly12.png",
		"/assets/image/quillme/slotMachine/fly13.png",
		"/assets/image/quillme/slotMachine/fly14.png",
		"/assets/image/quillme/slotMachine/fly15.png",
		"/assets/image/quillme/slotMachine/fly16.png",
		"/assets/image/quillme/slotMachine/bg.png",
		"/assets/image/quillme/slotMachine/bgw.png",
		"/assets/image/quillme/slotMachine/bgl.png",
		"/assets/image/quillme/slotMachine/btn0.png",
		"/assets/image/quillme/slotMachine/btn1.png",
		"/assets/image/quillme/slotMachine/btnpress.png",
		"/assets/image/quillme/slotMachine/ccli.png",
		"/assets/image/quillme/slotMachine/cdef.png",
		"/assets/image/quillme/slotMachine/chov.png",
		"/assets/image/quillme/slotMachine/hand0.png",
		"/assets/image/quillme/slotMachine/hand1.png",
		"/assets/image/quillme/slotMachine/icons.png",
		"/assets/image/quillme/slotMachine/lose.png",
		"/assets/image/quillme/slotMachine/machine.png",
		"/assets/image/quillme/slotMachine/neon0.png",
		"/assets/image/quillme/slotMachine/neon1.png",
		"/assets/image/quillme/slotMachine/neon2.png",
		"/assets/image/quillme/slotMachine/wel0.png",
		"/assets/image/quillme/slotMachine/wel1.png",
		"/assets/image/quillme/slotMachine/win.png"
	];
	var percents = [
		1, 5, 7, 9, 13, 20, 23, 23, 25, 29, 35, 37, 39, 44, 47, 48, 49, 50, 52, 55, 58, 60, 62, 64, 66, 68, 70, 73, 77, 80, 85, 88, 90, 93, 96, 100
	];

	function preload() {
			var t = 0;
			for(var s = 0; s < sources.length; s ++) {
				var img = new Image();
				img.src = sources[s];
				if(img.complete) {
					t ++;
					if(t < percents.length)
						pb.odProgressbar('option', 'value', percents[t]/100);
					if(t >= percents.length - 1)
						$('#od_pb').slideUp('slow');					
				} else {
					img.onload = function() {
						t ++;
						if(t < percents.length)
							pb.odProgressbar('option', 'value', percents[t]/100);
						img.onload = null;
						if(t >= percents.length - 1)
							$('#od_pb').slideUp('slow');
					}
				};	
			};
	};

	preload();

	/* Initialize */
	var neon, welcome, button, background;
	var n = 0, w = 0, b = 0, bg = 0;
	var ost = [0, 0, 0];
	var win = -1;		//-1: NOT SET
	var turns = 30;
	var isplaying = false;
	var fna = [0, 0, 0];
	var flag = true;
	neon = window.setInterval(function() {
			n %= 3;
			$(".neon" + (n % 3)).show();
			$(".neon" + ((n + 1) % 3)).hide();
			$(".neon" + ((n + 2) % 3)).hide();
			n ++;
	}, 200);
	welcome = window.setInterval(function() {
			w %= 2;
			$(".welcome" + (w % 2)).show();
			$(".welcome" + ((w + 1) % 2)).hide();
			w ++;
	}, 500);
	button = window.setInterval(function() {
			b %= 2;
			$(".button" + (b % 2)).show();
			$(".button" + ((b + 1) % 2)).hide();
			b ++;
	}, 500);
	for(var i = 0; i < 3; i ++) {
			ost[i] = 25 + 45 * parseInt(Math.random() * 5);
			$(".icons-rotate" + i).css("top", "-" + ost[i] + "px");
	};
	/* Initialize End */


	if(typeof(window.win_order_id) !== 'undefined' && window.win_order_id != ''){
		//中奖，已提交订单，刷新页面情况	
		$(".win").children('p').text("恭喜您！抽到了" + window.win_prize_title + "！").end().animate({"top": "65px"}, 800, "easeOutBounce");
		$(".win button").text('查看').click(function() {
			window.location.href = '/users/orders?scope=2';
		})		
	}else if(typeof(window.win_prize_id) !== 'undefined' && window.win_prize_id != ''){
		//中奖,未提交订单，刷新页面
		$(".win").children('p').text("恭喜您！抽到了" + window.win_prize_title + "！").end().animate({"top": "65px"}, 800, "easeOutBounce");
		$(".win button").click(function() {
			popup_address_page();
		})		
	}else if(typeof(window.error_code != 'undefined') && window.error_code != ''){
		//违规操作未中奖情况
		if(window.error_code == 'error__11'){
			$(".lose p").text("对不起,该次回答的抽奖机会已被领取,请不要继续抽奖！");
		}else{
			$(".lose p").text("对不起,该问卷不存在抽奖机会！");
		}		
	}else if(window.lottery_result == 'false'){
		//正常抽奖未中的情况
		$(".lose").animate({"top": "65px"}, 800, "easeOutBounce");
		$(".lose button").click(function() {
			window.location.href = '/home';
		});			
	}		


	$(".machine-start").mousedown(function() {
			if(!isplaying) {
				window.clearInterval(button);
				$(".buttonpress").show();
				$(".button0").hide();
				$(".button1").hide();
				for(var i = 0; i < 3; i ++)
					$(".icons-rotate" + i).css("top", "-=10px");
			};
	});


	
	$(".machine-start").mouseup(function() {
		if(!isplaying) {
			isplaying = true;
			var u = 0;

			$.getJSON(
				'/lotteries/' + window._id + '/draw',
				{},
				function(retval) {
					console.log(retval)
					if(retval.success) {
						if(retval.value.result) {
							fnl = 25 + 45 * parseInt(Math.random() * 5);		//write this in the retval  win!
							win = true;
							window.win_prize_id = retval.value.prize_id
							window.win_prize_title = retval.value.prize_title
							$(".win p").text("恭喜您！抽到了" + retval.value.prize_title + "！");
							$(".win button").click(function() {
								//$(".win").hide();
								popup_address_page()
							})
						} else {
							do {													//write this in the retval lose...
								for(var i = 0; i < 3; i ++) {
									fna[i] = 25 + 45 * parseInt(Math.random() * 5);
								};
							} while((fna[0] == fna[1]) && (fna[1] == fna[2]));
							for(var i = 0; i < 3; i ++) {
								$(".icons-rotate" + i).data("fna", fna[i]);
							};
							win = false;
							$(".lose button").click(function() {
								window.location.href = '/home';
							});
						}	
					} else {	
						win = false;
						if(retval.value.error_code == 'error__11'){
							$(".lose p").text("对不起,该次回答的抽奖机会已被领取,请不要继续抽奖！");
						}else{
							$(".lose p").text("对不起,该问卷不存在抽奖机会！");
						}
						$(".lose button").click(function() {
							window.location.href = '/home';
						});						
					}
				}						
			);

			$(".buttonpress").hide();
			$(".button0").show();
			$(".button1").show();		
			button = window.setInterval(function() {
				u %= 2;
				$(".button" + (u % 2)).show();
				$(".button" + ((u + 1) % 2)).hide();
				u ++;
			}, 500);
			for(var i = 0; i < 3; i ++) {
				$(".icons-rotate" + i).animate({"top": "0px"}, parseInt(Math.random() * 800), "linear", rotate);
			};
		};

		function rotate() {
			if((win == -1) || (turns != 0)) {		//Not Get Results OR Get Results But Rotates Not Finish.
				turns --;
				$(this).css("top", "-225px");
				$(this).animate({"top": "0px"}, parseInt(Math.random() * 800), "linear", rotate);
			} else if(win && (turns == 0)) {
				$(this).css("top", "-225px");	
				$(this).animate({"top": "-" + fnl + "px"}, 800, "easeOutBounce", function() {
					background = window.setInterval(function() {
						bg %= 2;
						$(".background" + (bg % 2)).show();
						$(".background" + ((bg + 1) % 2)).hide();
						bg ++;
					}, 500);
					setTimeout(function() {
						$(".fly1").animate({"left":"50px", "top":"50px"}, 500);
						$(".fly2").animate({"left":"190px", "top":"10px"}, 500);
						$(".fly3").animate({"left":"20px", "top":"110px"}, 500);
						$(".fly4").animate({"left":"30px", "top":"210px"}, 500);
						$(".fly5").animate({"left":"60px", "top":"310px"}, 500);
						$(".fly6").animate({"left":"300px", "top":"10px"}, 500);
						$(".fly7").animate({"left":"420px", "top":"0px"}, 500);
						$(".fly8").animate({"left":"300px", "top":"550px"}, 500);
						$(".fly9").animate({"left":"550px", "top":"50px"}, 500);
						$(".fly10").animate({"left":"600px", "top":"100px"}, 500);
						$(".fly11").animate({"left":"570px", "top":"200px"}, 500);
						$(".fly12").animate({"left":"500px", "top":"370px"}, 500);
						$(".fly13").animate({"left":"550px", "top":"502px"}, 500);
						$(".fly14").animate({"left":"580px", "top":"300px"}, 500);
						$(".fly15").animate({"left":"0px", "top":"0px"}, 500);
						$(".fly16").animate({"left":"160px", "top":"496px"}, 500);
						$(".fly17").animate({"left":"0px", "top":"500px"}, 500);
						$(".fly18").animate({"left":"47px", "top":"437px"}, 500);
						$(".fly19").animate({"left":"600px", "top":"570px"}, 500);
						setTimeout(function() {$(".win").animate({"top": "65px"}, 800, "easeOutBounce");}, 300);
					}, 1000);				
				});		

			} else if(!win && (turns == 0)) {
				$(this).css("top", "-225px");
				$(this).animate({"top": "-" + $(this).data("fna") + "px"}, 800, "easeOutBounce", function() {
					setTimeout(function() {
						$(".background2").show();
						$(".background0").hide();
						$(".lose").animate({"top": "65px"}, 800, "easeOutBounce");
					}, 1000);
				});
			}
		}		
	});


	//共用的弹出框函数
	function popup(obj,redirect,another_redirect){
    	$.fancybox.open([
    			{href : obj}
    		],
				{
					beforeShow: function(){
						//placeholder_for_ie()
						$.placeholder();
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
    			width:500,
    			padding:10,
    			scrolling:  'no'
				}
    	);
	}



	function fill_order_confirm_data(obj){

    //确认地址信息
    $('span[name="receiver"]').attr('data',window.sample_receiver).text(window.sample_receiver)
		$('span[name="address"]').attr('data',window.sample_address).text(window.sample_real_address)
		$('span[name="postcode"]').attr('data',window.sample_postcode).text(window.sample_postcode)
    $('span[name="mobile"]').attr('data',window.sample_mobile).text(window.sample_mobile)
    
    
    $('span[name="info_sys"]').attr('data',window.info_sys)
    $('span[name="street_info"]').attr('data',window.sample_street_info).text(window.sample_street_info)
	}



	function popup_address_page(){
		//获取收获地址
		popup("#recever")
    get_recerver_info()
	}
	

  //获取收获地址
  function get_recerver_info(){
  	if(typeof(window.sample_receiver) != 'undefined'){
      	$('input[name="receiver"]').val(window.sample_receiver)
      	$('input[name="mobile"]').val(window.sample_mobile)
      	$('input[name="postcode"]').val(window.sample_postcode)
      	$('textarea[name="street_info"]').val(window.sample_street_info)
      }

      if($('div.address-slt').length < 1){
				window.addressSelector = $.od.odAddressSelector({ precision: 2, // 0. province, 1. city, 2. town, 3. detail 
				has_postcode: false, 
				value: { address: window.sample_address, 
									detail: '', postcode: '' 
								} 
				}).appendTo('#recerver_address');
      }

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


  function generate_orders(button,order_obj){
    button.val('正在提交......').attr('disabled',true).addClass('disabled')  	
    $.postJSON('/orders/create_lottery_order.json',{order_info:order_obj},function(retval){
      	if(retval.success){
      		button.val('继续提交').attr('disabled',false).removeClass('disabled')
      		$.postJSON('/answers/'+ window._id+ '/start_bind',{},function(result){
     				console.log(result)
      		} )			
      		$(".win button").text('查看').off('click').on('click', function(){
      			window.location.href = '/users/orders?scope=2';
      		});		   		
      		popup_order_ok_page();
      	}else{
      		console.log(retval)
      	}
    })
  }


	function popup_order_ok_page(){
		if(typeof(window.username) != 'undefined'){
			popup("#order_ok",'sign_in','users/orders?scope=2')
		}else{
			popup("#order_ok",'sign_in','sign_up')	
		}
		
  }


  	//popup window  input elements focus 
  	$('div.exc_notices  input').on('focus',function(){
  		$(this).removeClass('error')
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
			order_data['answer_id'] = window._id
			generate_orders($(this),order_data)
		}else{
			//确认地址信息
			var go_on = check_enter()

			if(go_on){
				popup_address_confirm_page()
			}			
		}
	})


	$('a.repair_address').on('click',function(){
		popup_address_page();
	})	

  //关闭弹出框按钮
	$('input.close_f').on('click',function(){
		var redirect = $(this).attr('data');
		if(redirect){
			window.location.href = '/' + redirect;
		}else{
			$.fancybox.close();	
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
		if(!receiver_reg.test(receiver) || default_receiver.test(receiver)){
			$('input[name="receiver"]').addClass('error')
		}else if(!mobile_partten.test(mobile)){
			$('input[name="mobile"]').addClass('error')
		}else if(!postcode_reg.test(postcode)){
			$('input[name="postcode"]').addClass('error')
		}else if(province < 0 || city < 0 || town < 0){
			$('span.notice').show()	
		}else if(street_info.length < 1 || street_info_partten.test(street_info)){
			$('textarea').addClass('error')
		} else{
			$('span.notice').hide()	
			go = true
		}

		return go
				
	}
})
