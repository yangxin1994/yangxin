//=require ui/widgets/od_popup

jQuery(function($) {
	var type = window.window.quality_control_questions_type;
	var ids = window.quality_control_questions_ids;
	var temp = 2;		//random insertion as default
	console.log(ids);

	/* initialize */
	showPanel(type);
	var interval = true;
	$(".objective").each(function() {
		if(interval)
			$(this).addClass("interval");
		interval = !interval;
		var id = $("input", this).attr("id");
		for(var n = 0; n < ids.length; n ++) {
			if(ids[n] == id)
				$("input", this).attr("checked", true)
		};
	});
	interval = true;
	$(".matching").each(function() {
		if(interval)
			$(this).addClass("interval");
		interval = !interval;
		var id = $("input", this).attr("id");
		for(var n = 0; n < ids.length; n ++) {
			if(ids[n] == id)
				$("input", this).attr("checked", true)
		};	
	});	
	/* initialize end */

	$("#inputA").click(function() {
		if(this.checked)
			type = temp;
		else {
			temp = type;
			type = 0;
			ids = [];
			$(".quality-list input").attr("checked", false);
		};
		showPanel(type);
	});

	$("#radioB li").click(function() {
		if($(this).index() == 0) {
			type = 2;
			ids = [];
			$(".quality-list input").attr("checked", false);
		} else if($(this).index() == 1)
			type = 1;
		showPanel(type);
	});

	$(".icon-seach").click(function() {
		$(this).parent().siblings("p").slideToggle();
	});

	$("#radioC li").click(function() {
		$(this).siblings().removeClass("now");
		$(this).siblings().find("em").removeClass("ture");
		$(this).addClass("now");
		$("em", this).addClass("ture");
		if($(this).index() == 0) {
			$("#caption-h2").text("标准答案题质控");
			$("#objectives").show();
			$("#matchings").hide();
		} else if($(this).index() == 1) {
			$("#caption-h2").text("答案一致题质控");
			$("#objectives").hide();
			$("#matchings").show();			
		}
	});


	$("#confirm").click(function() {
		ids = [];
		$(".quality-list input").each(function() {
			if(this.checked) {
				ids.push($(this).attr("id"));
			};		
		});
		$(this).attr("disabled", "disabled");
		$.putJSON(
			'/questionaires/' + window.survey_id + '/quality',
			{
				quality_control_questions_type: type,
				quality_control_questions_ids: ids
			},
			function(retval) {
				$("#confirm").removeAttr("disabled");
				if(retval.success) {
					$.od.odPopup({title: "提示", content: "设置成功！"});	
				} else {
					var msg = ((retval.value.error_code == 'error_80') ? '设置失败，您所选择的质控题可能已被删除。' : '设置失败，请刷新页面重试。');
					$.od.odPopup({title: "提示", content: msg});
				}
			}						
		);		
	})

	function showPanel(t) {
		switch(t) {
			case 2:
				$("#radioB li").eq(0).removeClass("f14 g6").addClass("now b f14 g3");
				$("#radioB li").eq(0).find("em").addClass("ture");
				$("#radioB li").eq(1).removeClass("now b f14 g3").addClass("f14 g6");
				$("#radioB li").eq(1).find("em").removeClass("ture");
				$("#inputA").attr("checked", true);
				$("#mainA").show();
				$("#lineA").show();
				$("#bottomA").hide();
				$("#mainB").show();
				$("#lineB").hide();
				$("#bottomB").show();
				$("#mainC").hide();
				$("#bottomC").hide();
				$(".bottom").css("margin-top", "0px");
				break;
			case 1:
				$("#radioB li").eq(1).removeClass("f14 g6").addClass("now b f14 g3");
				$("#radioB li").eq(1).find("em").addClass("ture");
				$("#radioB li").eq(0).removeClass("now b f14 g3").addClass("f14 g6");
				$("#radioB li").eq(0).find("em").removeClass("ture");			
				$("#inputA").attr("checked", true);
				$("#mainA").show();
				$("#lineA").show();
				$("#bottomA").hide();
				$("#mainB").show();
				$("#lineB").show();
				$("#bottomB").hide();
				$("#mainC").show();
				$("#bottomC").show();
				$(".bottom").css("margin-top", "10px");
				break;
			case 0: 
			default:
				$("#mainA").show();
				$("#lineA").hide();
				$("#bottomA").show();
				$("#mainB").hide();
				$("#lineB").hide();
				$("#bottomB").hide();
				$("#mainC").hide();
				$("#bottomC").hide();
				$(".bottom").css("margin-top", "0px");
				break;			
		};
	}
});