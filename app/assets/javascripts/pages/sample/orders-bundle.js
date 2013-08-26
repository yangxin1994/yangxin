//=require ui/widgets/od_popup

jQuery(function($) {
	var current = Number(($.util.param('page') ? $.util.param('page') : 1));
	$(".pagination .current").text(current + "/" + window.total_page);
	if(current < 1 || current > window.total_page) {
		$(".pagination .next-gray").hide();
		$(".pagination .prev-gray").hide();
		if(window.total_page == 0)
			$(".pagination .current").text("暂无订单")
		else
			$(".pagination .current").text("页码错误");
	} else {
		if(current == window.total_page)
			$(".pagination .next-gray").hide();
		if(current == 1)
			$(".pagination .prev-gray").hide();			
	};
});