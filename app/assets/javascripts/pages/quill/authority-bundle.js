//=require ui/widgets/od_popup

jQuery(function($) {
	var authority = window.survey_authority;
	console.log(authority);
	var password_type = authority.password_control.password_type;

	/* initialize */
	switch(password_type) {
		case -1:
			$("#password-control").attr("checked", false);
			$("#question-main").hide();
			break;
		case 0:
			$("#password-control").attr("checked", true);
			$("#question-main").show();
			$("#radiobox").find("li").eq(password_type).addClass("now");
			$("#radiobox").find("li").eq(password_type).children().addClass("ture");
			$("#single-password").show();
			$("#single-password input").val(authority.password_control.single_password);
			break;
		case 1:
			$("#password-control").attr("checked", true);
			$("#question-main").show();
			$("#radiobox").find("li").eq(password_type).addClass("now");
			$("#radiobox").find("li").eq(password_type).children().addClass("ture");
			var passwords = "";
			var password_list = authority.password_control.password_list;
			for(var i = 0; i < password_list.length; i ++)
				passwords += password_list[i].content + "\n";
			$("#multi-password").show();
			$("#multi-password textarea").val(passwords);
			break;
		case 2:
			$("#password-control").attr("checked", true);
			$("#question-main").show();
			$("#radiobox").find("li").eq(password_type).addClass("now");
			$("#radiobox").find("li").eq(password_type).children().addClass("ture");
			var passwords = "";
			var user_passes = authority.password_control.username_password_list;
			for(var i = 0; i < user_passes.length; i ++) {
				var content = user_passes[i].content;
				if(content != null && content.length == 2)
					passwords += content[0] + "," + content[1] + "\n";
			};
			$("#user-password").show();
			$("#user-password textarea").val(passwords);
			break;												
	};
	// if(authority.has_captcha)
	// 	$("#has-captcha").attr("checked", true);
	// else
	// 	$("#has-captcha").attr("checked", false);

	// if(authority.times_for_one_computer != -1) {
	// 	$("#times-for-pc").attr("checked", true);
	// 	//$("#times").attr("disabled", false);
	// 	//$("#times").val(authority.times_for_one_computer);
	// } else {
	// 	$("#times-for-pc").attr("checked", false);
	// 	//$("#times").attr("disabled", true);		
	// };
	/* initialize end */


	$("#password-control").click(function() {
		if(this.checked) {
			$("#question-main").show();
			if(password_type == -1) {
				password_type = 0;		//The default is 0
				$("#radiobox").find(".now").removeClass("now");
				$("#radiobox").find(".ture").removeClass("ture");
				$("#radiobox").find("li").eq(password_type).addClass("now");
				$("#radiobox").find("li").eq(password_type).children().addClass("ture");
				$("#single-password").show();
				$("#multi-password").hide();
				$("#user-password").hide();
			}
		} else {
			$("#question-main").hide();
			password_type = -1;
		};
	});

	$("#radiobox").find("li").each(function() {
		$(this).click(function() {
			$("#radiobox").find(".now").removeClass("now");
			$("#radiobox").find(".ture").removeClass("ture");
			$(this).addClass("now");
			$(this).children().addClass("ture");
			password_type = $(this).index();

			switch(password_type) {
				case 0:
					$("#single-password").show();
					$("#multi-password").hide();
					$("#user-password").hide();
					break;
				case 1:
					$("#single-password").hide();
					$("#multi-password").show();
					$("#user-password").hide();
					break;
				case 2:
					$("#single-password").hide();
					$("#multi-password").hide();
					$("#user-password").show();
					break;					
			}


		});
	});

	/*
	$("#times-for-pc").click(function() {
		$("#times").attr("disabled", ((this.checked) ? false : true));
		$("#times").val("");
	});
	*/


	$('#confirm_btn button').click(function() {
		authority.password_control.password_type = password_type;
		switch(password_type) {
			case -1:
				break;
			case 0:
				if($("#single-password #password").val() == "") {
					$.od.odPopup({
						content: '<p class="mt10 ml10 f6">请填写密码信息</p>'
					});
					return;	
				} else
					authority.password_control.single_password = $.trim($("#single-password #password").val());
				break;
			case 1:
				authority.password_control.password_list = [];
				var txra = $("#multi-password #password").val();
				if(txra != "") {
					var passwords = txra.split("\n");				
					for(var i = 0; i < passwords.length; i ++) {
						if(passwords[i] != "") {
							var password = {
								content: $.trim(passwords[i]),
								used: false
							};
							authority.password_control.password_list.push(password);						
						};
					};
				} else {
					$.od.odPopup({
						content: '<p class="mt10 ml10 f6">请填写密码信息</p>'
					});
					return;						
				};
				break;
			case 2:
				authority.password_control.username_password_list = [];
				var txra = $("#user-password #password").val();
				if(txra != "") {
					var user_passes = txra.split("\n");				
					for(var i = 0; i < user_passes.length; i ++) {
						var user_pass = user_passes[i];
						if(user_pass != "") {
							var content = user_pass.split(/[,，]/);
							console.log(content[0]=="");
							if(content.length != 2 || ($.trim(content[0]) == "" || $.trim(content[1]) == "")) {
								$.od.odPopup({
									content: '<p class="mt10 ml10 f6">请输入正确的密码列表</p>'
								});
								return;						
							};
							authority.password_control.username_password_list.push({
								content: [$.trim(content[0]), $.trim(content[1])],
								used: false
							});							
						};
					};
				} else {
					$.od.odPopup({
						content: '<p class="mt10 ml10 f6">请填写密码信息</p>'
					});
					return;						
				};
				break;
		};

		// authority.has_captcha = ($("#has-captcha").attr("checked")) ? true : false;
		
		/*
		if(!$("#times").attr("disabled")) {
			var times = $("#times").val();
			var reg = /^\d+$/;
			if(!reg.test(times)) {
				$.od.odPopup({
					content: '<p class="mt10 ml10 f6">请输入正确的答题次数</p>',
					size:{width:150,height:100,titleHeight:15}
				});
				return;
			} else
				authority.times_for_one_computer = Number(times);
		} else
			authority.times_for_one_computer = -1;
		*/
		// if($("#times-for-pc").attr("checked"))
		// 	authority.times_for_one_computer = 1
		// else
		// 	authority.times_for_one_computer = -1;

		$(this).attr("disabled", "disabled");
		$.putJSON(
			'/questionaires/' + window.survey_id + '/authority.json',
			{
				authority: authority
			},
			function(retval) {
				$('#confirm_btn button').removeAttr("disabled");
				if(retval.success) {
					$.od.odPopup({title: "提示", content: "设置成功！"});
				} else {
					$.od.odPopup({title: "提示", content: "设置失败 :(.<br/>错误代码：" + retval.value.error_code});
				}
			}						
		);	
	});
});