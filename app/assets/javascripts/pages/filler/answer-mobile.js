//=require quill/views/survey_filler_mobile
//=require underscore-min
//=require backbone
//=require weixin

jQuery(function($) {
	//微信红包问卷
	if(window.is_wechart){
		window.appid     	= <%= raw (@appid).to_json %>;
		window.noncestr  	= <%= raw (@noncestr).to_json %>;    
		window.timestamp 	= <%= raw (@timestamp).to_json %>;
		window.url       	= <%= raw (@url).to_json %>;
		window.signure   	= <%= raw (@signure).to_json %>;
		window.share_link   = window.location.origin + '/s/' + <%= raw @reward_scheme_id.to_json %>;
		wx.config({
		    debug: true,
		    appId: window.appid,
		    timestamp: window.timestamp,
		    nonceStr: window.noncestr,
		    signature: window.signure,
		    jsApiList: ['onMenuShareTimeline','onMenuShareAppMessage','hideMenuItems']
		})

		wx.ready(function(){
			arr = ["menuItem:share:qq","menuItem:share:weiboApp","menuItem:favorite","menuItem:share:facebook","menuItem:share:QZone",
				   "menuItem:editTag","menuItem:editTag","menuItem:delete","menuItem:copyUrl","menuItem:originPage","menuItem:readMode",
				   "menuItem:openWithQQBrowser","menuItem:openWithSafari","menuItem:share:email","menuItem:share:brand"]
			wx.hideMenuItems({
			    menuList: arr
			});
	
			wx.onMenuShareTimeline({
			    title: '答问卷领红包,大家快来抢啊!!!',
			    link: window.share_link,
			    imgUrl: '/assets/images/od-quillme/favicon.ico'
			});
	
			wx.onMenuShareAppMessage({
			    title: '答问卷领红包,大家快来抢啊!!!', // 分享标题
			    desc: '问卷吧邀您一起答问卷抢红包,答题越多奖励越多!!!',
			    link: window.share_link,
			    imgUrl: '/assets/images/od-quillme/favicon.ico'
			});
		})
	}
});



