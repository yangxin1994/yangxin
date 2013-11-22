//=require ui/widgets/od_popup

jQuery(function($) {

	/* ===========================
	 * Spreadable
	 * =========================== */
	// if($('#spread').length > 0) {
	// 	var href_ipt = $('#spread input').mouseover(function(e) {
	// 		$(e.target).select();
	// 	});
	// 	var href = href_ipt.val();
	// 	$('#spread button').click(function() {
	// 		if (window.clipboardData) {	//IE
	// 			window.clipboardData.setData("Text", href);
	// 			$.od.odPopup({ content: '链接已经复制至剪贴板' });
	// 		} else {
	// 			$.od.odPopup({ 
	// 				content: '选中输入框链接进行复制', 
	// 				close: function() { href_ipt.select(); }
	// 			});
	// 		};	
	// 	});
	// 	// sharing
	// 	_.each(['SinaWeibo', 'TencentWeibo', 'Renren', 'Douban', 'QQSpace', 
	// 		'Kaixin001', 'Diandian', 'Gmail', 'Fetion'], function(v) {
	// 		$('#spread .icon-' + v).click(function() {
	// 			$.social['shareTo' + v](href, '亲，帮忙填写一份问卷哦~');
	// 		});
	// 	});

	window.spread_dom = $('#spread').detach();
	// }

});