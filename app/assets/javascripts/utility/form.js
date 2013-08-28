(function($){

	$.form = $.form || {};

	$.extend($.form,{
		//账户中心下拉菜单
		powerfloat:function(){
			$(".user-head-box").powerFloat({
				offsets: {
					x:0,
					y:-1
				},
				zIndex:888,
				eventType: "hover",
			    target: $("#account-pull-down"),
			    position:"1-3",
			    showCall: function() {
    	    	$(this).addClass("hover");    
		      },
		      hideCall: function() {
		          $(this).removeClass("hover");
		      }  
			});			
		},		
	})
})(jQuery)