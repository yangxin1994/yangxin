jQuery(function($) {
	var folded_current = Number(($.util.param('f') ? $.util.param('f') : 1));
	var drawn_current = Number(($.util.param('d') ? $.util.param('d') : 1)); 
	var past_current = Number(($.util.param('p') ? $.util.param('p') : 1)); 	
	$("#folded_lotteries .current").text(folded_current + "/" + window.folded_total);
	$("#drawn_lotteries .current").text(drawn_current + "/" + window.drawn_total);
	$("#past_lotteries .current").text(past_current + "/" + window.past_total);

	if(folded_current < 1 || folded_current > window.folded_total) {
		$("#folded_lotteries .next-gray").hide();
		$("#folded_lotteries .prev-gray").hide();
		if(window.folded_total == 0)
			$("#folded_lotteries .current").text("暂无抽奖信息");
		else
			$("#folded_lotteries .current").text("页码错误");
	} else {
		if(folded_current == window.folded_total)
			$("#folded_lotteries .next-gray").hide();
		if(folded_current == 1)
			$("#folded_lotteries .prev-gray").hide();			
	};

	if(drawn_current < 1 || drawn_current > window.drawn_total) {
		$("#drawn_lotteries .next-gray").hide();
		$("#drawn_lotteries .prev-gray").hide();
		if(window.drawn_total == 0)
			$("#drawn_lotteries .current").text("暂无中奖信息");
		else
			$("#drawn_lotteries .current").text("页码错误");
	} else {
		if(drawn_current == window.drawn_total)
			$("#drawn_lotteries .next-gray").hide();
		if(drawn_current == 1)
			$("#drawn_lotteries .prev-gray").hide();			
	};

	if(past_current < 1 || past_current > window.past_total) {
		$("#past_lotteries .next-gray").hide();
		$("#past_lotteries .prev-gray").hide();
		if(window.past_total == 0)
			$("#past_lotteries .current").text("暂无中奖信息");
		else
			$("#past_lotteries .current").text("页码错误");
	} else {
		if(past_current == window.past_total)
			$("#past_lotteries .next-gray").hide();
		if(past_current == 1)
			$("#past_lotteries .prev-gray").hide();			
	};	
});