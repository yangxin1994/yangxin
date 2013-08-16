jQuery(function($) {
	var url = $("#link-address").val();
	var copy = $('.copyLink').click(function() {
		if (window.clipboardData) {							//IE
			window.clipboardData.setData("Text", url);
			$.od.odPopup({content:'<p class="mt10 ml10 f6">已复制!</p>'});
		} else {											//!IE		
			alert("请选中文本然后鼠标右键或者 ctrl+c 复制");
			$(this).prev().select();
		};	
	});
	var share_title = '欢迎加入 OopsData 调研社区，在这里您可以答题获取现金或礼品奖励，更有大奖（ipad/iphone/macbook）等你来抽取。';
	$(".gmail-share").click(function() {
		$.social.shareToGmail(url, share_title);
	});
	$(".douban-share").click(function() {
		$.social.shareToDouban(url, share_title);
	});
	$(".renren-share").click(function() {
		$.social.shareToRenren(url, share_title);
	});	
	$(".diandian-share").click(function() {
		$.social.shareToDiandian(url, share_title);
	});
	$(".sina-share").click(function() {
		$.social.shareToSinaWeibo(url, share_title);
	});
	$(".fetion-share").click(function() {
		$.social.shareToFetion(url, share_title);
	});	
	$(".kaixin-share").click(function() {
		$.social.shareToKaixin001(url, share_title);
	});
	$(".qzone-share").click(function() {
		$.social.shareToQQSpace(url, share_title);
	});
	$(".tencent-share").click(function() {
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

	var current = Number(($.util.param('page') ? $.util.param('page') : 1));
	$(".pagination .current").text(current + "/" + window.total_page);
	if(current < 1 || current > window.total_page) {
		$(".pagination .next-gray").hide();
		$(".pagination .prev-gray").hide();
		if(window.total_page == 0)
			$(".pagination .current").text("暂无好友记录")
		else
			$(".pagination .current").text("页码错误");
	} else {
		if(current == window.total_page)
			$(".pagination .next-gray").hide();
		if(current == 1)
			$(".pagination .prev-gray").hide();			
	};
});