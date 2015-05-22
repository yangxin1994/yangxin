//(function($){

	function submitvrcode(){
		$.post("/vrcode/codes",{img_id: $("#image_id").val(), remote_ip:$("#remote_ip").val(), code:$("#code").val()}, function(data){
			console.log(data)
			//alert("Your answer has been submitted.  Please fill the next~~~");
			if (data.value.url ===  undefined )  
			{
				$(".vrcode>span").hide();
			}else{
				$(".vrcode>span").show();
				$("#image_id").val(data.value.id);
				$("#remote_ip").val(data.value.ip);
				$(".vrcode>img").attr("src",data.value.url)
				$("#grades").text(data.value.succ);
				$("#correct").text(data.value.succ);
				$("#wrong").text(data.value.fail);
				$("#judging").text(data.value.judge);
				$("#total").text(data.value.commit);
				$("#code").val("") ;
			}
		},"json");
	}

//})(jQuery)
