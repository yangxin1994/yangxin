//=require ui/widgets/od_progressbar
//=require ui/widgets/od_popup

jQuery(function($) {
	if(window.status == 0 && window.lottery_status > 1) {	//Slot Machine
		$(".sidebar-box").addClass("has-slot");
		var pb = $.od.odProgressbar({color: "#6D91A9", width: 500, value: 0});
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
						console.log(retval);
						if(retval.success) {
							console.log("success");
							if(retval.value.status != 1) {
								fnl = 25 + 45 * parseInt(Math.random() * 5);		//write this in the retval  win!
								win = true;
								$(".win p").text("恭喜您！抽到了" + retval.value.prize.name + "！");
								$(".win button").click(function() {
									window.location.reload();
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
									window.location = '/lotteries/own';
								});
							}	
						} else {
							console.log("error");
							var message = retval.value.error_message
							if(retval.value.error_code == "error_21701")
								message = "该抽奖可能因为过期已被删除，请咨询管理员"
							else if(retval.value.error_code == "error_21702")
								message = "该抽奖暂时被关闭，请稍后再来或咨询管理员";
							$.od.odPopup({popupStyle: "quillme", title: "提示",
								content: "兑换出错 :(.<br/>错误代码：" + retval.value.error_code + "<br/>错误信息：" + message,
								confirm: function() {window.location = '/lotteries/own';}
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
							$(".fly1").animate({"left":"115px", "top":"70px"}, 500);
							$(".fly2").animate({"left":"190px", "top":"60px"}, 500);
							$(".fly3").animate({"left":"210px", "top":"110px"}, 500);
							$(".fly4").animate({"left":"180px", "top":"210px"}, 500);
							$(".fly5").animate({"left":"200px", "top":"310px"}, 500);
							$(".fly6").animate({"left":"250px", "top":"210px"}, 500);
							$(".fly7").animate({"left":"270px", "top":"160px"}, 500);
							$(".fly8").animate({"left":"470px", "top":"50px"}, 500);
							$(".fly9").animate({"left":"550px", "top":"50px"}, 500);
							$(".fly10").animate({"left":"650px", "top":"100px"}, 500);
							$(".fly11").animate({"left":"618px", "top":"200px"}, 500);
							$(".fly12").animate({"left":"700px", "top":"70px"}, 500);
							$(".fly13").animate({"left":"742px", "top":"102px"}, 500);
							$(".fly14").animate({"left":"740px", "top":"160px"}, 500);
							$(".fly15").animate({"left":"690px", "top":"250px"}, 500);
							$(".fly16").animate({"left":"652px", "top":"376px"}, 500);
							$(".fly17").animate({"left":"160px", "top":"270px"}, 500);
							$(".fly18").animate({"left":"647px", "top":"237px"}, 500);
							$(".fly19").animate({"left":"618px", "top":"200px"}, 500);
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

	} else if(window.status == 2 && window.lottery_code != null && window.lottery_code.prize != null) {	//Order
		$(".information input").blur(function() {
			$(this).next().text("*");
			$(this).removeClass("error");
		});
		$(".information textarea").blur(function() {
			$(this).next().text("*");
			$(this).removeClass("error");
		});

		$("#order-virtual").click(function() {
			var is_return = false;
			if($('#yourName').val() == "") {
				$("#yourName").addClass("error");
				$("#name-star").text("* 请输入姓名");
				is_return = true;
			};
			if($('#PhoneNumber').val() == "") {
				$('#PhoneNumber').addClass("error");
				$("#phone-star").text("* 请输入手机号");
				is_return = true;			
			} else if (!$.regex.isMobile($('#PhoneNumber').val())) {
				$('#PhoneNumber').addClass("error");
				$("#phone-star").text("* 请输入正确的手机号");
				is_return = true;				
			};
			if(is_return)
				return;
			$(this).attr("disabled", "disabled");
			$.postJSON(
				'/orders.json',
				{
					order: {
						lottery_code_id: window._id,
						gift_id: window.prize_id,
						is_prize: true,
						type: 2,
						full_name: $('#yourName').val(),
						phone: $('#PhoneNumber').val(),
						is_update_user: ($("#is-update-user").attr("checked") ? true : false)
					} 
				},
				function(retval) {
					$("#order-virtual").removeAttr("disabled");
					if(retval.success) {
						$.od.odPopup({popupStyle: "quillme", title: "提示", content: "兑换成功！", confirm: function() {
							window.location = '/orders/' +	retval.value._id;
						}});
					} else {
						$.od.odPopup({popupStyle: "quillme", title: "提示", content: "兑换出错 :(.<br/>错误代码：" + retval.value.error_code});
					}
				}
			);
		});

		$("#order-entity").click(function() {
			var is_return = false;
			if($('#yourName').val() == "") {
				$("#yourName").addClass("error");
				$("#name-star").text("* 请输入姓名");
				is_return = true;
			};
			if($('#PhoneNumber').val() == "") {
				$('#PhoneNumber').addClass("error");
				$("#phone-star").text("* 请输入手机号");
				is_return = true;			
			} else if (!$.regex.isMobile($('#PhoneNumber').val())) {
				$('#PhoneNumber').addClass("error");
				$("#phone-star").text("* 请输入正确的手机号");
				is_return = true;				
			};
			if($("#Address").val() == "") {
				$("#Address").addClass("error");
				$("#address-star").text("* 请输入地址");
				is_return = true;
			};
			if($('#postalCode').val() == "") {
				$('#postalCode').addClass("error");
				$("#code-star").text("* 请输入邮编");
				is_return = true;			
			} else if (!$.regex.isPostcode($('#postalCode').val())) {
				$('#postalCode').addClass("error");
				$("#code-star").text("* 请输入正确的邮编");
				is_return = true;				
			};		
			if(is_return)
				return;
			$(this).attr("disabled", "disabled");
			$.postJSON(
				'/orders.json',
				{
					order: {
						lottery_code_id: window._id,
						gift_id: window.prize_id,
						is_prize: true,
						type: 1,
						full_name: $('#yourName').val(),
						phone: $('#PhoneNumber').val(),
						address: $('#Address').val(),
						postcode: $('#postalCode').val(),
						is_update_user: ($("#is-update-user").attr("checked") ? true : false)
					} 
				},
				function(retval) {
					$("#order-entity").removeAttr("disabled");
					if(retval.success) {
						$.od.odPopup({popupStyle: "quillme", title: "提示", content: "兑换成功！", confirm: function() {
							window.location = '/orders/' +	retval.value._id;
						}});
					} else {
						$.od.odPopup({popupStyle: "quillme", title: "提示", content: "兑换出错 :(.<br/>错误代码：" + retval.value.error_code});
					}
				}
			);
		});

		$("#order-cash").click(function() {
			var is_return = false;
			if($('#yourName').val() == "") {
				$("#yourName").addClass("error");
				$("#name-star").text("* 请输入姓名");
				is_return = true;
			};
			if($('#PhoneNumber').val() == "") {
				$('#PhoneNumber').addClass("error");
				$("#phone-star").text("* 请输入手机号");
				is_return = true;			
			} else if (!$.regex.isMobile($('#PhoneNumber').val())) {
				$('#PhoneNumber').addClass("error");
				$("#phone-star").text("* 请输入正确的手机号");
				is_return = true;				
			};
			if($('#PID').val() == "") {
				$('#PID').addClass("error");
				$("#id-star").text("* 请输入身份证号");
				is_return = true;			
			} else if (!$.regex.isIDCard($('#PID').val())) {
				$('#PID').addClass("error");
				$("#id-star").text("* 请输入正确的身份证号");
				is_return = true;				
			};
			if($("#alipay").val() == "") {
				if($("#bankcard-number").val() == "") {
					$("#bankcard-number").addClass("error");
					$("#card-star").text("* 请输入银行或支付宝账号");
					is_return = true;
				} else if($("#bank-name").val() == "") {
					$("#bank-name").addClass("error");
					$("#bank-star").text("* 请输入银行或支付宝账号");
					is_return = true;				
				} else {
					//判断银行账号有效性
				}
			} else {
				//判断支付宝账号有效性
				//如银行账号不空判断银行账号有效性
			};
			if(is_return)
				return;
			$(this).attr("disabled", "disabled");
			$.postJSON(
				'/orders.json',
				{
					order: {
						lottery_code_id: window._id,
						gift_id: window.prize_id,
						is_prize: true,
						type: 0,
						full_name: $('#yourName').val(),
						phone: $('#PhoneNumber').val(),
						identity_card: $('#PID').val(),
						alipay_account: $('#alipay').val(),
						bankcard_number: $('#bankcard-number').val(),
						bank: $('#bank-name').val(),
						is_update_user: ($("#is-update-user").attr("checked") ? true : false)
					} 
				},
				function(retval) {
					$("#order-cash").removeAttr("disabled");
					if(retval.success) {
						$.od.odPopup({popupStyle: "quillme", title: "提示", content: "兑换成功！", confirm: function() {
							window.location = '/orders/' +	retval.value._id;
						}});
					} else {
						$.od.odPopup({popupStyle: "quillme", title: "提示", content: "兑换出错 :(.<br/>错误代码：" + retval.value.error_code});
					}
				}
			);
		});
	};
});