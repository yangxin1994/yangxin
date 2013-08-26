jQuery(function($) {
	var current = Number(($.util.param('pi') ? $.util.param('pi') : 1));
	$("#pagination .current").text(current + "/" + window.total_page);
	if(current < 1 || current > window.total_page) {
		$("#pagination .next").hide();
		$("#pagination .previous").hide();
		if(window.total_page == 0)
			$("#pagination .current").text("暂无消息")
		else
			$("#pagination .current").text("页码错误");
	} else {
		if(current == window.total_page)
			$("#pagination .next").hide();
		if(current == 1)
			$("#pagination .previous").hide();			
	};
	$("#pagination .next").click(function() {
		$.util.param('pi', current + 1);
	});
	$("#pagination .previous").click(function() {
		$.util.param('pi', current - 1);
	});
	$(".messages li").click(function() {
		if($(this).data("is_open") == undefined || $(this).data("is_open") == false) {
			$(this).addClass("graybg");
			$(this).find("p").show();
			$(this).data("is_open", true);
		} else {
			$(this).find("p").hide();
			$(this).removeClass("graybg");
			$(this).data("is_open", false);
		}
	});
});