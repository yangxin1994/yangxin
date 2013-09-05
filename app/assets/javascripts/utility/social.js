/* ================================
 * Provide social sharing methods
 * ================================ */
(function($){

	$.social = $.social || {};

	/* sharing
	 * =============================== */
	function _share(target, params) {
		params = params || {};
		var temp = [];
		for( var p in params ){
			temp.push(p + '=' + encodeURIComponent( params[p] || '' ) )
		};
		window.open(target + temp.join('&'));
	}
	function _getPic(pic) {
		return pic;
		// return pic ? pic : 'http://' + location.host + '/assets/logo.png';
	}
	function _getTitle(title) {
		return title ? title : '分享链接：';
	}

	/* Share to social network
	 * =============================== */
	$.extend($.social, {
		shareToSinaWeibo: function(url, title, pic) {
			_share("http://service.weibo.com/share/share.php?", {
				url: url,
				title: _getTitle(title),	/**分享的文字内容(可选，默认为所在页面的title)*/
				pic: _getPic(pic),	/**分享图片的路径(可选)*/
				appkey:'',	/**申请的appkey,显示分享来源(可选)*/
				ralateUid:'',	/**关联用户的UID，分享微博会@该用户(可选)*/
				language:'zh_cn'	/**设置语言，zh_cn|zh_tw(可选)*/		
			});
		},
		shareToTencentWeibo: function(url, title, pic) {
			_share("http://share.v.t.qq.com/index.php?c=share&a=index&", {
				url: url,
				title: _getTitle(title),
				pic: _getPic(pic),
				appkey: '',
				site: ''
			});
		},
		shareToDouban: function(url, title, pic) {
			_share("http://shuo.douban.com/!service/share?", {
				href: url,
				name: _getTitle(title),
				image: _getPic(pic)
			});	
		},
		shareToRenren: function(url, title, pic) {
			_share("http://widget.renren.com/dialog/share?", {
				resourceUrl : url,						//分享的资源Url
				srcUrl: url,		//分享的资源来源Url,默认为header中的Referer,如果分享失败可以调整此值为resourceUrl试试
				title: _getTitle(title),					//分享的标题
				pic: _getPic(pic),									//分享的主题图片Url
				description: ''							//分享的详细描述
			});
		},
		shareToQQSpace: function(url, title, pic) {
			_share("http://sns.qzone.qq.com/cgi-bin/qzshare/cgi_qzshare_onekey?", {
				url: url,
				title: _getTitle(title),		/*分享标题(可选)*/
				pics: _getPic(pic), 					/*分享图片的路径(可选)*/
				desc:'',					/*默认分享理由(可选)*/
				summary:'',					/*分享摘要(可选)*/
				site: 'OopsData',					/*分享来源 如：腾讯网(可选)*/
			});
		},
		shareToKaixin001: function(url, title, pic) {
			_share("http://www.kaixin001.com/rest/records.php?", {
				url: url,
				content: _getTitle(title),
				pic: _getPic(pic),									//分享的主题图片Url
				starid: '',
				aid: '',
				style: 11
			});	
		},
		shareToDiandian: function(url, title, pic) {
			_share("http://www.diandian.com/share?", {
				ti: _getTitle(title),
				lo: url,
				type: 'link'
			});
		},
		shareToFetion: function(url, title, pic) {
			_share("http://i2.feixin.10086.cn/app/api/share?", {
				Source: '',
				Title: _getTitle(title),
				Url: url
			});
		},
		shareToGmail: function(url, title, pic) {
			_share("https://mail.google.com/mail/?ui=2&view=cm&fs=1&tf=1&", {
				su: _getTitle(title),
				body: url
			});
		}
	});

})(jQuery);