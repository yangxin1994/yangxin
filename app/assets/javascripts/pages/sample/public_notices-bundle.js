jQuery(function($) {
	var share_url = window.location.href;
	var title = $('div.pub_title').text();
	$.each(['SinaWeibo', 'TencentWeibo', 'Renren', 'Douban', 'QQSpace',
		'Kaixin001', 'Diandian', 'Gmail', 'Fetion'
	], function(index, v) {
		$('a.' + v).click(function() {
			$.social['shareTo' + v](share_url, title);
		});
	});
});