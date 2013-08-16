//=require ui/widgets/od_popup
jQuery(function($) {
	var spread_current = Number(($.util.param('s') ? $.util.param('s') : 1));
	var my_spread_current = Number(($.util.param('m') ? $.util.param('m') : 1));
	$("#spread_surveys .current").text(spread_current + "/" + window.spread_total);
	$("#my_spread_surveys .current").text(my_spread_current + "/" + window.my_spread_total);

	if(spread_current < 1 || spread_current > window.spread_total) {
		$("#spread_surveys .next-gray").hide();
		$("#spread_surveys .prev-gray").hide();
		if(window.spread_total == 0)
			$("#spread_surveys .current").text("暂无礼品");
		else
			$("#spread_surveys .current").text("页码错误");
	} else {
		if(spread_current == window.spread_total)
			$("#spread_surveys .next-gray").hide();
		if(spread_current == 1)
			$("#spread_surveys .prev-gray").hide();			
	};

	if(my_spread_current < 1 || my_spread_current > window.my_spread_total) {
		$("#my_spread_surveys .next-gray").hide();
		$("#my_spread_surveys .prev-gray").hide();
		if(window.my_spread_total == 0)
			$("#my_spread_surveys .current").text("暂无礼品");
		else
			$("#my_spread_surveys .current").text("页码错误");
	} else {
		if(my_spread_current == window.my_spread_total)
			$("#my_spread_surveys .next-gray").hide();
		if(my_spread_current == 1)
			$("#my_spread_surveys .prev-gray").hide();			
	};

	var copy = $('.copyLink').click(function() {
		if (window.clipboardData) {							//IE
			window.clipboardData.setData("Text", $(this).prev().val());
			$.od.odPopup({content:'<p class="mt10 ml10 f6">已复制!</p>'});
		} else {											//!IE		
			alert("请选中文本然后鼠标右键或者 ctrl+c 复制");
			$(this).prev().select();
		};	
	});
	var share_title = '亲，帮忙填写一份问卷哦，感激涕零>_<。';
	$(".gmail-share").click(function() {
		var url = $(this).parent().parent().prev().prev().val();
		$.social.shareToGmail(url, share_title);
	});
	$(".douban-share").click(function() {
		var url = $(this).parent().parent().prev().prev().val();
		$.social.shareToDouban(url, share_title);
	});
	$(".renren-share").click(function() {
		var url = $(this).parent().parent().prev().prev().val();
		$.social.shareToRenren(url, share_title);
	});	
	$(".diandian-share").click(function() {
		var url = $(this).parent().parent().prev().prev().val();
		$.social.shareToDiandian(url, share_title);
	});
	$(".sina-share").click(function() {
		var url = $(this).parent().parent().prev().prev().val();
		$.social.shareToSinaWeibo(url, share_title);
	});
	$(".fetion-share").click(function() {
		var url = $(this).parent().parent().prev().prev().val();
		$.social.shareToFetion(url, share_title);
	});	
	$(".kaixin-share").click(function() {
		var url = $(this).parent().parent().prev().prev().val();
		$.social.shareToKaixin001(url, share_title);
	});
	$(".qzone-share").click(function() {
		var url = $(this).parent().parent().prev().prev().val();
		$.social.shareToQQSpace(url, share_title);
	});
	$(".tencent-share").click(function() {
		var url = $(this).parent().parent().prev().prev().val();
		$.social.shareToTencentWeibo(url, share_title);
	});
	$(".gmail-share").hover(
		function() {$("img", this).attr("src", "../assets/social/gmail-02.png")},
		function() {$("img", this).attr("src", "../assets/social/gmail-01.png")}
	);	
	$(".douban-share").hover(
		function() {$("img", this).attr("src", "../assets/social/douban-02.png")},
		function() {$("img", this).attr("src", "../assets/social/douban-01.png")}
	);	
	$(".renren-share").hover(
		function() {$("img", this).attr("src", "../assets/social/renren-02.png")},
		function() {$("img", this).attr("src", "../assets/social/renren-01.png")}
	);	
	$(".diandian-share").hover(
		function() {$("img", this).attr("src", "../assets/social/diandian-02.png")},
		function() {$("img", this).attr("src", "../assets/social/diandian-01.png")}
	);	
	$(".sina-share").hover(
		function() {$("img", this).attr("src", "../assets/social/sina-02.png")},
		function() {$("img", this).attr("src", "../assets/social/sina-01.png")}
	);	
	$(".fetion-share").hover(
		function() {$("img", this).attr("src", "../assets/social/fetion-02.png")},
		function() {$("img", this).attr("src", "../assets/social/fetion-01.png")}
	);	
	$(".kaixin-share").hover(
		function() {$("img", this).attr("src", "../assets/social/kaixin-02.png")},
		function() {$("img", this).attr("src", "../assets/social/kaixin-01.png")}
	);	
	$(".qzone-share").hover(
		function() {$("img", this).attr("src", "../assets/social/qzone-02.png")},
		function() {$("img", this).attr("src", "../assets/social/qzone-01.png")}
	);	
	$(".tencent-share").hover(
		function() {$("img", this).attr("src", "../assets/social/tencent-02.png")},
		function() {$("img", this).attr("src", "../assets/social/tencent-01.png")}
	);							
});