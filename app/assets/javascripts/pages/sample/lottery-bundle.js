//=require ui/widgets/od_popup
jQuery(function($) {
	$(".exchange-lotterycode").click(function() {
		var lottery_id = $(this).attr("id");
		var point = $(this).attr("point");
		var content = "";
		var exchangeable = false;
		if(Number(point) < Number(window.total_point)) {
			content = "兑换此抽奖需要" + point + "积分，是否兑换？"	;
			exchangeable = true;		
		} else
			content = "兑换此抽奖需要" + point + "积分，您的积分不足，无法兑换。";
		$.od.odPopup({popupStyle: "quillme", type: "confirm", title: "提示", content: content, confirm: function() {
			if(exchangeable) {			
				$.postJSON(
					'/lotteries/' + lottery_id + '/exchange.json',
					{},
					function(retval) {
						if(retval.success) {
							$.od.odPopup({popupStyle: "quillme", title: "提示", content: "兑换成功！", confirm: function() {
								window.location = '/lotteries/own';
							}});
						} else {
							$.od.odPopup({popupStyle: "quillme", title: "提示", content: "兑换出错 :(.<br/>错误代码：" + retval.value.error_code});
						}
					}
				);				
			}
		}});
	});	
});