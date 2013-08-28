(function($){

	$.form = $.form || {};

	$.extend($.form,{
		placeholder:function(){//为了兼容IE的placeholder不支持的情况专门定制了这个function
			$.each(['input','textarea'],function(index,value){
				$(value + '[placeholder]').each(function(){  
				    var input = $(this);        
				    $(input).val(input.attr('placeholder'));
				    $(input).focus(function(){
						if (input.val() == input.attr('placeholder')) {
						   input.val('');
						}
				    });
				    $(input).blur(function(){
				    	if (input.val() == '' || input.val() == input.attr('placeholder')) {
				    	    input.val(input.attr('placeholder'));
				    	}
				    });
				});
			})			
		},

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