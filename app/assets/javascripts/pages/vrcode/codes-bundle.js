//(function($){

	function submitvrcode(){
		//document.getElementsById("edit_user_51aea34deb0e5b571f000079").submit();
		var img_id  = $("#image_id").val();
		var remote_ip= $("#remote_ip").val();
		var code = $("#code").val();
		$.post("/vrcode/codes",{img_id: img_id, remote_ip:remote_ip, code:code}, function(data){
			console.log(data)
		},"json");
	}

//})(jQuery)
