//(function($){

	function submitvrcode(){
		$.post("/vrcode/codes",{img_id: $("#image_id").val(), remote_ip:$("#remote_ip").val(), code:$("#code").val()}, function(data){
			$("#image_id").val(data.value.id);
			$("#remote_ip").val(data.value.ip);
			$(".vrcode>img").attr("src",data.value.url)
			$("#grades").val(data.value.commit);
			$("#correct").val(data.value.succ);
			$("#wrong").val(data.value.fail);
			$("#judging").val(data.value.judge);
			$("#total").val(data.value.commit);
			$("#code").val("") ;
		},"json");
	}

//})(jQuery)
