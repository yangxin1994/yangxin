//=require ui/widgets/od_popup


// $('button.reedm_right_now')click(function(){
// 	if($(this).hasClass('not_login')){
		
// 	}else{
		
// 	}
// });
// jQuery(function($) {
// 	$("input").blur(function() {
// 		$(this).next().text("*");
// 		$(this).removeClass("error");
// 	});
// 	$("textarea").blur(function() {
// 		$(this).next().text("*");
// 		$(this).removeClass("error");
// 	});

// 	$("#order-lottery").click(function() {
// 		$(this).attr("disabled", "disabled");
// 		$.postJSON(
// 			'/orders.json',
// 			{
// 				order: {
// 					gift_id: window._id,
// 					type: 3
// 				} 
// 			},
// 			function(retval) {
// 				$("#order-lottery").removeAttr("disabled");
// 				if(retval.success) {
// 					$.od.odPopup({popupStyle: "quillme", title: "提示", content: "兑换成功！", confirm: function() {
// 						window.location = '/orders/' +	retval.value._id;
// 					}});
// 				} else {
// 					$.od.odPopup({popupStyle: "quillme", title: "提示", content: "兑换出错 :(.<br/>请刷新页面重试。"});
// 				}
// 			}
// 		);
// 	});

// 	$("#order-virtual").click(function() {
// 		var is_return = false;
// 		if($('#yourName').val() == "") {
// 			$("#yourName").addClass("error");
// 			$("#name-star").text("* 请输入姓名");
// 			is_return = true;
// 		};
// 		if($('#PhoneNumber').val() == "") {
// 			$('#PhoneNumber').addClass("error");
// 			$("#phone-star").text("* 请输入手机号");
// 			is_return = true;			
// 		} else if (!$.regex.isMobile($('#PhoneNumber').val())) {
// 			$('#PhoneNumber').addClass("error");
// 			$("#phone-star").text("* 请输入正确的手机号");
// 			is_return = true;				
// 		};
// 		if(is_return)
// 			return;
// 		$(this).attr("disabled", "disabled");
// 		$.postJSON(
// 			'/orders.json',
// 			{
// 				order: {
// 					gift_id: window._id,
// 					type: 2,
// 					full_name: $('#yourName').val(),
// 					phone: $('#PhoneNumber').val(),
// 					is_update_user: ($("#is-update-user").attr("checked") ? true : false)
// 				} 
// 			},
// 			function(retval) {
// 				$("#order-virtual").removeAttr("disabled");
// 				if(retval.success) {
// 					$.od.odPopup({popupStyle: "quillme", title: "提示", content: "兑换成功！", confirm: function() {
// 						window.location = '/orders/' +	retval.value._id;
// 					}});
// 				} else {
// 					$.od.odPopup({popupStyle: "quillme", title: "提示", content: "兑换出错 :(.<br/>错误代码：" + retval.value.error_code});
// 				}
// 			}
// 		);
// 	});

// 	$("#order-entity").click(function() {
// 		var is_return = false;
// 		if($('#yourName').val() == "") {
// 			$("#yourName").addClass("error");
// 			$("#name-star").text("* 请输入姓名");
// 			is_return = true;
// 		};
// 		if($('#PhoneNumber').val() == "") {
// 			$('#PhoneNumber').addClass("error");
// 			$("#phone-star").text("* 请输入手机号");
// 			is_return = true;			
// 		} else if (!$.regex.isMobile($('#PhoneNumber').val())) {
// 			$('#PhoneNumber').addClass("error");
// 			$("#phone-star").text("* 请输入正确的手机号");
// 			is_return = true;				
// 		};
// 		if($("#Address").val() == "") {
// 			$("#Address").addClass("error");
// 			$("#address-star").text("* 请输入地址");
// 			is_return = true;
// 		};
// 		if($('#postalCode').val() == "") {
// 			$('#postalCode').addClass("error");
// 			$("#code-star").text("* 请输入邮编");
// 			is_return = true;			
// 		} else if (!$.regex.isPostcode($('#postalCode').val())) {
// 			$('#postalCode').addClass("error");
// 			$("#code-star").text("* 请输入正确的邮编");
// 			is_return = true;				
// 		};		
// 		if(is_return)
// 			return;
// 		$(this).attr("disabled", "disabled");
// 		$.postJSON(
// 			'/orders.json',
// 			{
// 				order: {
// 					gift_id: window._id,
// 					type: 1,
// 					full_name: $('#yourName').val(),
// 					phone: $('#PhoneNumber').val(),
// 					address: $('#Address').val(),
// 					postcode: $('#postalCode').val(),
// 					is_update_user: ($("#is-update-user").attr("checked") ? true : false)
// 				} 
// 			},
// 			function(retval) {
// 				$("#order-entity").removeAttr("disabled");
// 				if(retval.success) {
// 					$.od.odPopup({popupStyle: "quillme", title: "提示", content: "兑换成功！", confirm: function() {
// 						window.location = '/orders/' +	retval.value._id;
// 					}});
// 				} else {
// 					$.od.odPopup({popupStyle: "quillme", title: "提示", content: "兑换出错 :(.<br/>错误代码：" + retval.value.error_code});
// 				}
// 			}
// 		);
// 	});

// 	$("#order-cash").click(function() {
// 		var is_return = false;
// 		if($('#yourName').val() == "") {
// 			$("#yourName").addClass("error");
// 			$("#name-star").text("* 请输入姓名");
// 			is_return = true;
// 		};
// 		if($('#PhoneNumber').val() == "") {
// 			$('#PhoneNumber').addClass("error");
// 			$("#phone-star").text("* 请输入手机号");
// 			is_return = true;			
// 		} else if (!$.regex.isMobile($('#PhoneNumber').val())) {
// 			$('#PhoneNumber').addClass("error");
// 			$("#phone-star").text("* 请输入正确的手机号");
// 			is_return = true;				
// 		};
// 		if($('#PID').val() == "") {
// 			$('#PID').addClass("error");
// 			$("#id-star").text("* 请输入身份证号");
// 			is_return = true;			
// 		} else if (!$.regex.isIDCard($('#PID').val())) {
// 			$('#PID').addClass("error");
// 			$("#id-star").text("* 请输入正确的身份证号");
// 			is_return = true;				
// 		};
// 		if($("#alipay").val() == "") {
// 			if($("#bankcard-number").val() == "") {
// 				$("#bankcard-number").addClass("error");
// 				$("#card-star").text("* 请输入银行或支付宝账号");
// 				is_return = true;
// 			} else if($("#bank-name").val() == "") {
// 				$("#bank-name").addClass("error");
// 				$("#bank-star").text("* 请输入银行或支付宝账号");
// 				is_return = true;				
// 			} else {
// 				//判断银行账号有效性
// 			}
// 		} else {
// 			//判断支付宝账号有效性
// 			//如银行账号不空判断银行账号有效性
// 		};
// 		if(is_return)
// 			return;
// 		$(this).attr("disabled", "disabled");
// 		$.postJSON(
// 			'/orders.json',
// 			{
// 				order: {
// 					gift_id: window._id,
// 					type: 0,
// 					full_name: $('#yourName').val(),
// 					phone: $('#PhoneNumber').val(),
// 					identity_card: $('#PID').val(),
// 					alipay_account: $('#alipay').val(),
// 					bankcard_number: $('#bankcard-number').val(),
// 					bank: $('#bank-name').val(),
// 					is_update_user: ($("#is-update-user").attr("checked") ? true : false)
// 				} 
// 			},
// 			function(retval) {
// 				$("#order-cash").removeAttr("disabled");
// 				if(retval.success) {
// 					$.od.odPopup({popupStyle: "quillme", title: "提示", content: "兑换成功！", confirm: function() {
// 						window.location = '/orders/' +	retval.value._id;
// 					}});
// 				} else {
// 					$.od.odPopup({popupStyle: "quillme", title: "提示", content: "兑换出错 :(.<br/>错误代码：" + retval.value.error_code});
// 				}
// 			}
// 		);
// 	});
// });