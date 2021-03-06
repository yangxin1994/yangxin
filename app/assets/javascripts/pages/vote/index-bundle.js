jQuery(function(){
	var aLi = $('#being-hit .li-container > li');
	aLi.each(function(index, el){
	    if((index+1)%4==0){
	        $(el).css('margin-right','0');
	    };
	});
	var oLi = $('#upcoming .li-container > li');
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
			if($(this).hasClass('voted')){
				$(this).find('.tip').hide();
			}else{
				$(this).find('.tip').show();
			}
		}, function() {
			if($(this).hasClass('voted')){
				return false;
			}
			$(this).find('.shadow-txt').stop().animate({top: -230}, 300);
			$(this).find('.content').stop().animate({top: -230}, 300);
			$(this).find('.tip').hide();
		});
	};
	voteMove(aLi);
	voteMove(oLi);

	function vote(el,beingHit){
		el.click(function(){
			$(this).closest('li').addClass('voted');
			$(this).parent().siblings('.shadow-txt').css('height', '230');
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
		data: {vt:number,movie_id:This.data('id')},
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
	})

	.fail(function() {
		alert('error:投票失败,请重试');
	})
	.always(function() {
		// console.log("complete");
	})
};



