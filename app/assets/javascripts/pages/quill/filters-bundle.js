//=require ui/widgets/od_left_icon_button
//=require ui/widgets/od_popup

jQuery(function($) {
	var filters_size = window.survey_filters.length;
	var pages = window.survey_questions.pages;

	for(var i = 0; i < filters_size; i ++) {
		var filter = window.survey_filters[i];

		var $tlt = $('<div />');
		$tlt.addClass("title-list-txt");
		if(i == (filters_size-1))
			$tlt.attr("style", "border:none");
		var $fbpl = $('<h2 />');
		$fbpl.addClass("f14 b pt10 l");
		$fbpl.text(filter.name);
		var $ul = $('<ul />');
		$ul.addClass("g9 l");

		for(var j = 0; j < filter.conditions.length; j ++) {
			for(var p = 0; p < pages.length; p ++) {
				var page = pages[p];
				for(var q = 0; q < page.questions.length; q ++) {
					var question = page.questions[q];
					if((question.question_type == 0) && (question._id == filter.conditions[j].name)) {	//Only Choice Type can be conditions
						var $li = $('<li />');
						$li.addClass("g9");
						$li.html("&nbsp;&nbsp;&nbsp;&nbsp;" + question.content.text + " ( ");
						for(var t = 0; t < filter.conditions[j].value.length; t ++) {
							for(var v = 0; v < question.issue.items.length; v ++) {
								var item = question.issue.items[v];
								if(item.id == filter.conditions[j].value[t]) {
									var $span = $('<span />');
									if(t == 0)
										$span.text(item.content.text)
									else
										$span.text("、" + item.content.text);
									$span.appendTo($li);
								};
							};
							if(question.issue.other_item.has_other_item) {	//has other item
								var other = question.issue.other_item;
								if(other.id == filter.conditions[j].value[t]) {
									var $span = $('<span />');
									$span.text("、" + other.content.text);
									$span.appendTo($li);
								}
							}
						};
						$li.append(" )");

						if(filter.conditions[j].fuzzy) {
							var $span = $('<span />');
							$span.text(" [模糊匹配]");
							$span.appendTo($li);
						};

						$li.appendTo($ul);
					}
				};
			} 
		};

		$tlt.appendTo("#filters");
		$fbpl.appendTo($tlt);

		var $span = $('<span />');
		$span.addClass("r");
		$fbpl.after($ul);
		$ul.after($span);
		var $iie = $('<em title="编辑"/>');
		$iie.addClass("icon icon-edit mr10");
		$iie.appendTo($span);
		var $iid = $('<em title="删除"/>');
		$iid.addClass("icon icon-del");
		var $wait = $('<span class="load-white"/>');
		$wait.addClass("waiting");
		
		$iie.after($iid);
		$iid.after($wait);
		
		
	}


	var libtn = $.od.odLeftIconButton({text: '添加筛选器', icon: 'add', width: 100});
	libtn.appendTo('#add-filter');

	var add = function() {
		$(".icon-edit").unbind("click", edit);
		$(".icon-del").unbind("click", del);
		$("#add-filter").children().unbind("click", add);			
		window.location = '/questionaires/' +	window.survey_id + '/filters/' + filters_size;
	};

	var edit = function() {
		$(".icon-edit").unbind("click", edit);
		$(".icon-del").unbind("click", del);
		$("#add-filter").children().unbind("click", add);			
		var index = $(this).parent().parent().index();
		window.location = '/questionaires/' +	window.survey_id + '/filters/' + index;
	};

	var del = function() {
		$(".icon-edit").unbind("click", edit);
		$(".icon-del").unbind("click", del);
		$("#add-filter").children().unbind("click", add);	
		var $del = $(this);
		$(this).hide();
		$(this).prev().hide();
		$(this).next().css("display", "inline-block");
		var $tlt = $(this).parent().parent();
		var index = $tlt.index();
		$.deleteJSON(
			'/questionaires/' + window.survey_id + '/filters/' + index + '.json',
			function(retval) {
				$(".icon-edit").bind("click", edit);
				$(".icon-del").bind("click", del);
				$("#add-filter").children().bind("click", add);	
				$del.next().hide();
				if(retval.success) {
					$tlt.slideUp("slow", function(){
						$tlt.remove();
						$(".title-list-txt:last").css("border", "none");
					});
				} else {
					$del.prev().show();
					$del.show();					
					$.od.odPopup({title: "提示", content: "删除失败 :(.<br/>错误代码：" + retval.value.error_code});
				}
			}
		);
	};

	$(".icon-edit").bind("click", edit);
	$(".icon-del").bind("click", del);
	$("#add-filter").children().bind("click", add);		
});