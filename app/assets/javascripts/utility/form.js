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
		enterSubmit:function(button){ //回车相应指定元素的点击事件，一般用于回车提交表单
			document.onkeydown = function(e){ 
				if(!e) e = window.event;//火狐中是 window.event 
				if((e.keyCode || e.which) == 13){ 
					$(button).click();
				} 
			} 			
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
		//以下函数返回对应名称的正则表达式

		isMobile:function(mobile){
			return (/^(13[0-9]|15[012356789]|18[0236789]|14[57])[0-9]{8}$/.test(mobile));
		},

		isEmail:function(email){
			return (/^(\w)+(\.\w+)*@(\w)+((\.\w{2,3}){1,3})$/.test(email));
		},

		isYidongNumber:function(number){
			return (/^1(3[4-9]|4[7]|5[012789]|8[2378])\d{8}$/.test(number));
		},

		isDianxinNumber:function(number){
			return (/^1([35]3|8[09])\d{8}$/.test(number));
		},

		isLianTongNumber:function(number){
			return (/^1(3[0-2]|4[5]|5[56]|8[0156])\d{8}$/.test(number));
		},

		isPostcode: function(postcode) {
			return (/\d{6}/.test(postcode));
		},

		isQq:function(qq){
			return (/^\d{5,}$/.test(qq));
		},

		isReceiver:function(receiver){
			return (/[a-zA-z0-9\u4E00-\u9FA5]/.test(receiver));
		},

		isDefaultReceiver:function(receiver){
			return (/姓名/.test(receiver));
		},

		isStreet:function(street){
			return (/街道地址/.test(street));
		}	

	})
})(jQuery)