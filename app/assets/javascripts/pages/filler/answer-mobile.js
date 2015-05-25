//=require quill/views/survey_filler_mobile
//=require underscore-min
//=require backbone
//=require weixin

jQuery(function($) {
	//微信红包问卷
	if(window.is_wechart){
		wx.ready(function(){
			arr = ["menuItem:share:qq","menuItem:share:weiboApp","menuItem:favorite","menuItem:share:facebook","menuItem:share:QZone",
				   "menuItem:editTag","menuItem:editTag","menuItem:delete","menuItem:copyUrl","menuItem:originPage","menuItem:readMode",
				   "menuItem:openWithQQBrowser","menuItem:openWithSafari","menuItem:share:email","menuItem:share:brand"]
			wx.hideMenuItems({
			    menuList: arr
			});
	
			wx.onMenuShareTimeline({
			    title: '答问卷领红包,大家快来抢!',
			    link: window.share_link,
			    imgUrl: window.location.origin + '/assets/od-quillme/favicon.ico'
			});
	
			wx.onMenuShareAppMessage({
			    title: '答问卷领红包,大家快来抢!',
			    desc: '问卷吧邀您一起答问卷抢红包,答题越多奖励越多!!!',
			    link: window.share_link,
			    imgUrl: window.location.origin + '/assets/od-quillme/favicon.ico'
			});
		})
		
	}
});



