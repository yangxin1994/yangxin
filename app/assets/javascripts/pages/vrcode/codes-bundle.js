//(function($){

	function submitvrcode(){
		$.post("/vrcode/codes",{img_id: $("#image_id").val(), remote_ip:$("#remote_ip").val(), code:$("#code").val()}, function(data){
			console.log(data)
			$("#image_id").val(data.value.id);
			$("#remote_ip").val(data.value.ip);
			$(".vrcode>img").attr("src",data.value.url)
		},"json");
	}

//})(jQuery)
