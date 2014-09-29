jQuery(function(){

	//判断cookie
	var str = getCookie('vote_id');
	if(str){
		var arr=str.split(',');
	};
	$('li .button-list .btn').each(function(index, el) {
		if(arr.indexOf($(el).data('id')) > -1){
			$(el).click();
		};
	});

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

	// 封装运动
	function voteMove(el){
		el.hover(function() {
			$(this).find('.shadow-txt').stop().animate({top: 0}, 300);
			$(this).find('.content').stop().animate({top: 0}, 300);
		}, function() {
			if($(this).hasClass('voted')){
				return false;
			}
			$(this).find('.shadow-txt').stop().animate({top: -230}, 300);
			$(this).find('.content').stop().animate({top: -230}, 300);
		});
	};
	voteMove(aLi);
	voteMove(oLi);

	function vote(el,beingHit){
		el.click(function(){
			$(this).closest('li').addClass('voted');
			if($(this).hasClass('want-to-see'))
			{
				voteAjax(0,$(this),beingHit);
			}
			else if($(this).hasClass('have-read'))
			{	
				voteAjax(2,$(this),beingHit);
			}
			else if($(this).hasClass('dont-want-to-see'))
			{
				voteAjax(1,$(this),beingHit);
			};
			$(this).parent().children().hide();
		});
	};
	vote($('#being-hit li .btn'),true);
	vote($('#upcoming li .btn'));
});

//封装
function voteAjax(number,This,beingHit){

	This.parent().siblings('span.content').html('<div class="loading"><img src="/assets/loadingb.gif"></div>');

	$.ajax({
		url: '/vote/suffrages/statrt_vote',
		type: 'GET',
		dataType: 'json',
		data: {vt:number,movie_id:$(this).data('id')},
	})

	.done(function(str) {
		if(beingHit)//正在热播
		{
			This.parent().siblings('span.content').html(
				'<h2>投票结果:</h2>'
				+'<p>已有'+str.value.total+'人投票</p>'
				+'<ul id="progress-bar-content">'
	      +'<li class="progress-xk"><b>想看:'+str.value.want+'人</b><span class="progress-bar"><span class="progress" style="width:'+ parseInt((str.value.want/str.value.total)*100) +'%;"></span></span>'
	      +'<span class="num">'+ parseInt((str.value.want/str.value.total)*100) +'%</span></li>'
	      +'<li class="progress-kg"><b>看过:'+str.value.seen+'人</b><span class="progress-bar"><span class="progress" style="width:'+ parseInt((str.value.seen/str.value.total)*100) +'%;"></span></span><span class="num">'+ parseInt((str.value.seen/str.value.total)*100) +'%</span></li>'
	      +'<li class="progress-bxk"><b>不想看:'+str.value.no_want+'人</b><span class="progress-bar"><span class="progress" style="width:'+ parseInt((str.value.no_want/str.value.total)*100) +'%;"></span></span><span class="num">'+ parseInt((str.value.no_want/str.value.total)*100) +'%</span></li>'
	    	+'</ul>'
			);
		}
		else //即将上映
		{
			This.parent().siblings('span.content').html(
				'<h2>投票结果:</h2>'
				+'<p>已有'+str.value.total+'人投票</p>'
				+'<ul id="progress-bar-content">'
	      +'<li class="progress-xk"><b>想看:'+str.value.want+'人</b><span class="progress-bar"><span class="progress" style="width:'+ parseInt((str.value.want/str.value.total)*100) +'%;"></span></span>'
	      +'<span class="num">'+ parseInt((str.value.want/str.value.total)*100) +'%</span></li>'
	      +'<li class="progress-bxk"><b>不想看:'+str.value.no_want+'人</b><span class="progress-bar"><span class="progress" style="width:'+ parseInt((str.value.no_want/str.value.total)*100) +'%;"></span></span><span class="num">'+ parseInt((str.value.no_want/str.value.total)*100) +'%</span></li>'
	    	+'</ul>'
			);
		};
		//存cookie
		var movies_id = getCookie('vote_id');
		if(movies_id) movies_id+=',';
		movies_id+=This.data('id');
		addCookie('vote_id',movies_id,10);
	})

	.fail(function() {
		alert('error:投票失败,请重试');
	})
	.always(function() {
		console.log("complete");
	})
};


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
	addCookie(name,'oopsdata',-10);
};


