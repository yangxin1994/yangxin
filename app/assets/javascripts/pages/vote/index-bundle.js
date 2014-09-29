 //投票页面
jQuery(function(){
	var aLi = $('#being-hit li');
	aLi.each(function(index, el){
	    if((index+1)%4==0){
	        $(el).css('margin-right','0');
	    };
	});
	var oLi = $('#upcoming li');
	oLi.each(function(index, el){
	    if((index+1)%4==0){
	        $(el).css('margin-right','0');
	    };
	});
	//遮罩动画
	$('#being-hit li').hover(function() {
		$(this).find('.shadow-txt').stop().animate({top: 0}, 300);
		$(this).find('.content').stop().animate({top: 0}, 300);
	}, function() {
		if(voted)
		{
			return false;
		}else{
			$(this).find('.shadow-txt').stop().animate({top: -230}, 300);
			$(this).find('.content').stop().animate({top: -230}, 300);
			voted = false;
		};
	});
	//AJAX
	$('#being-hit li a.btn').click(function(){
		var This = $(this);
		$(this).parent().voted = true;
		if($(this).hasClass('want-to-see'))
		{
			$.ajax({
				url: '/vote/suffrages/statrt_vote',
				type: 'GET',
				dataType: 'json',
				data: {vt: '1',movie_id:$(this).data('id')},
			})
			.done(function(str) {
				console.log(str.value);
				This.parent().siblings('span.content').html(
					'<h2>投票结果:</h2>'
					+'<p>已有'+str.value.total+'人投票</p>'
					+'<ul id="progress-bar-content">'
	                +'<li class="progress-xk"><b>想看:'+str.value.want+'人</b><span class="progress-bar"><span class="progress" style="width:'+ parseInt((str.value.want/str.value.total)*100) +'%;"></span></span>'
	                +'<span class="num">'+ parseInt((str.value.want/str.value.total)*100) +'%</span></li>'
	                +'<li class="progress-kg"><b>看过:'+str.value.seen+'人</b><span class="progress-bar"><span class="progress" style="width:'+ parseInt((str.value.seen/str.value.total)*100) +'%;"></span></span><span class="num">'+ parseInt((str.value.want/str.value.total)*100) +'%</span></li>'
	                +'<li class="progress-bxk"><b>不想看:'+str.value.no_want+'人</b><span class="progress-bar"><span class="progress" style="width:'+ parseInt((str.value.no_want/str.value.total)*100) +'%;"></span></span><span class="num">'+ parseInt((str.value.no_want/str.value.total)*100) +'%</span></li>'
	              	+'</ul>'
				);
			})
			.fail(function() {
				console.log("error");
			})
			.always(function() {
				console.log("complete");
			})
		}
		else if($(this).hasClass('have-read'))
		{
			console.log("3");	
		}
		else if($(this).hasClass('dont-want-to-see')){
			console.log("2");
		};
		$(this).parent().children().hide();
	});
});


//cookie框架
function addCookie(name,value,iHours){
	if(iHours){
		var oDate=new Date();
		oDate.setHours(oDate.getHours()+iHours);
		document.cookie=name+'='+value+';path=/;expires='+oDate;
	}else{
		document.cookie=name+'='+value+';path=/';	
	};
};
function getCookie(name){
	var arr=document.cookie.split('; ');
	for(var i=0; i<arr.length; i++){
		var arr2=arr[i].split('=');
		if(arr2[0]==name){
			return arr2[1];	
		};
	};
	return '';
};
function delCookie(name){
	addCookie(name,'123',-10);
};