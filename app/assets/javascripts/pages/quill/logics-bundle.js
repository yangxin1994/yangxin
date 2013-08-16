//=require ui/widgets/od_left_icon_button
//=require ui/widgets/od_popup

jQuery(function($) {
	var logic_size = window.survey_logics.length;
	var pages = window.survey_questions.pages;
	renderLs();

	function renderLs() {
		for(var i = 0; i < logic_size; i ++) {
			var logic = window.survey_logics[i];
			var $tlt = $('<div />');
			$tlt.addClass("title-list-txt");
			if(i == (logic_size - 1))
				$tlt.css("border", "none");
			var $fbp = $('<h2 />');
			$fbp.addClass("f14 b pt10 l");
			$fbp.text("约束" + String(i + 1));

			var $ul = $('<ul />');
			$ul.addClass("g9 l");

			var $condition = $('<p />');
			$condition.addClass("g9");
			$condition.text("约束条件：");
			$condition.appendTo($ul);
			for(var j = 0; j < logic.conditions.length; j ++) {
				for(var p = 0; p < pages.length; p ++) {
					var page = pages[p];
					for(var q = 0; q < page.questions.length; q ++) {
						var question = page.questions[q];
						if((question.question_type == 0) && (question._id == logic.conditions[j].question_id)) {	//Only Choice Type can be conditions
							var $li = $('<li />');
							$li.addClass("g9");
							$li.html("&nbsp;&nbsp;&nbsp;&nbsp;" + question.content.text + " (");
							for(var t = 0; t < logic.conditions[j].answer.length; t ++) {
								for(var v = 0; v < question.issue.items.length; v ++) {
									var item = question.issue.items[v];
									if(item.id == logic.conditions[j].answer[t]) {
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
									if(other.id == logic.conditions[j].answer[t]) {
										var $span = $('<span />');
										if(t == 0)
											$span.text(other.content.text)
										else
											$span.text("、" + other.content.text);
										$span.appendTo($li);
									}
								}
							};
							$li.append(" )");

							if(logic.conditions[j].fuzzy) {
								var $span = $('<span />');
								$span.text(" [模糊匹配]");
								$span.appendTo($li);
							};

							$li.appendTo($ul);
						}
					};
				} 
			};

			var $type = $('<p />');
			$type.addClass("g9");
			$type.html("约束类型：");
			$type.appendTo($ul);			
			switch(logic.rule_type) {
				case 0:
					$ul.append("&nbsp;&nbsp;&nbsp;&nbsp;停止答题");
					break;
				case 1:
					$ul.append("&nbsp;&nbsp;&nbsp;&nbsp;问题显示");
					break;
				case 2:
					$ul.append("&nbsp;&nbsp;&nbsp;&nbsp;问题隐藏");
					break;
				case 3:
					$ul.append("&nbsp;&nbsp;&nbsp;&nbsp;选项显示");
					break;
				case 4:
					$ul.append("&nbsp;&nbsp;&nbsp;&nbsp;选项隐藏");
					break;	
			};

			if(logic.rule_type == 1 || logic.rule_type == 2) {
				for(var j = 0; j < logic.result.length; j ++) {
					for(var p = 0; p < pages.length; p ++) {
						var page = pages[p];
						for(var q = 0; q < page.questions.length; q ++) {
							var question = page.questions[q];
							if(question._id == logic.result[j]) {
								if(j == 0) {
									var $result = $('<p />');
									$result.addClass("g9");
									$result.text("约束结果：");
									$result.appendTo($ul);
								};
								var $li = $('<li />');
								$li.addClass("g9");
								$li.html("&nbsp;&nbsp;&nbsp;&nbsp;" + question.content.text);
								$li.appendTo($ul);
							} 
						}
					}
				}
			} else if(logic.rule_type == 3 || logic.rule_type == 4) {
				for(var j = 0; j < logic.result.length; j ++) {
					for(var p = 0; p < pages.length; p ++) {
						var page = pages[p];
						for(var q = 0; q < page.questions.length; q ++) {
							var question = page.questions[q];
							if(question._id == logic.result[j].question_id) {
								if(j == 0) {
									var $result = $('<p />');
									$result.addClass("g9");
									$result.text("约束结果：");
									$result.appendTo($ul);
								};								
								var $li = $('<li />');
								$li.addClass("g9");
								$li.html("&nbsp;&nbsp;&nbsp;&nbsp;" + question.content.text + " (");
								if(question.question_type == 1 && logic.result[j].sub_questions != null) {			//MatrixChoice
									for(var t = 0; t < logic.result[j].sub_questions.length; t ++) {
										for(var v = 0; v < question.issue.rows.length; v ++) {
											var row = question.issue.rows[v];
											if(row.id == logic.result[j].sub_questions[t]) {
												var $span = $('<span />');
												if(t == 0)
													$span.text(row.content.text)
												else
													$span.text("、" + row.content.text);
												$span.appendTo($li);
											};
										};
									};
									$li.append(") (");									
								};
								if(logic.result[j].items != null) {
									for(var t = 0; t < logic.result[j].items.length; t ++) {
										for(var v = 0; v < question.issue.items.length; v ++) {
											var item = question.issue.items[v];
											if(item.id == logic.result[j].items[t]) {
												var $span = $('<span />');
												if(t == 0)
													$span.text(item.content.text)
												else
													$span.text("、" + item.content.text);
												$span.appendTo($li);
											};
										};
										if((question.issue.other_item != undefined) && (question.issue.other_item.has_other_item)) {	//has other item
											var other = question.issue.other_item;
											if(other.id == logic.result[j].items[t]) {
												var $span = $('<span />');
												if(t == 0)
													$span.text(other.content.text)
												else												
													$span.text("、" + other.content.text);
												$span.appendTo($li);
											}
										}
									};
								};
								$li.append(" )");
								$li.appendTo($ul);
							} 
						}
					}
				}
			}


			$tlt.appendTo($(".title-list"));
			$fbp.appendTo($tlt);

			var $span = $('<span />');
			$span.addClass("r");
			$fbp.after($ul);
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
			
		};
	};

	var libtn = $.od.odLeftIconButton({text: '添加新约束', icon: 'add', width: 100});
	libtn.appendTo('#add-restrain');

	var del = function() {
		$(".icon-edit").unbind("click", edit);
		$(".icon-del").unbind("click", del);
		$("#add-restrain").children().unbind("click", add);			
		var $del = $(this);
		$(this).hide();
		$(this).prev().hide();
		$(this).next().css("display", "inline-block");		
		var $logic = $(this).parent().parent();
		var index = $logic.index();
		$.deleteJSON(
			'/questionaires/' + window.survey_id + '/logics/' + index + '.json',
			function(retval) {
				$(".icon-edit").bind("click", edit);
				$(".icon-del").bind("click", del);
				$("#add-restrain").children().bind("click", add);					
				$del.next().hide();
				if(retval.success) {
					$logic.slideUp("slow", function(){
						$logic.remove();
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

	var edit = function() {
		$(".icon-edit").unbind("click", edit);
		$(".icon-del").unbind("click", del);
		$("#add-restrain").children().unbind("click", add);				
		var index = $(this).parent().parent().index();
		window.location = '/questionaires/' +	window.survey_id + '/logics/' + index;
	};

	var add = function() {
		$(".icon-edit").unbind("click", edit);
		$(".icon-del").unbind("click", del);
		$("#add-restrain").children().unbind("click", add);		
		window.location = '/questionaires/' +	window.survey_id + '/logics/' + logic_size;
	};

	$(".icon-edit").bind("click", edit);
	$(".icon-del").bind("click", del);
	$("#add-restrain").children().bind("click", add);		

});