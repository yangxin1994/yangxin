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

	// $('.button-list .btn').click(function(){
	// 	var mid = $(this).data('id');
	// 	var t   = $(this).data('t');
	// 	$.get('/vote/suffrages/statrt_vote',{movie_id:mid,vt:t},function(ret){
	// 		console.log(ret)
	// 	})
	// })



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