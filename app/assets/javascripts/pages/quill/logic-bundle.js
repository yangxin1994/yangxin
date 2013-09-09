//=require ui/widgets/od_popup
//=require quill/helpers


jQuery(function($) {

	//variables
	var pages = window.survey_questions.pages;
	var pages_len = pages.length;
	var logic = {};
	var position = -1;
	var current_logic = window.current_logic;
	var current_index = window.current_index;
	var is_update = (current_logic != null);

	renderQs();

	// button next
	$('#next_btn button').click(function() {
		$("#intr").hide();
		var $stw = $('<div />');
		$stw.addClass("seperator top white");
		var $qw = $('<div />');
		$qw.addClass("q-render white");
		var $sbw = $('<div />');
		$sbw.addClass("seperator bottom white");
		var $llm = $('<div />');
		$llm.addClass("logic-list-main");
	
		var $questions = $("input").filter(function(index) {return $(this).attr("name") == "question";});

		var first = true;
		var count = 0;
		$questions.each(function() {
			if(this.checked){
				count ++;
				var p_index = $(this).data("question").page;
				var q_posi = $(this).data("question").posi;
				var q_numb = $(this).data("question").numb;
				position = q_numb;				//indicate the last checked
				var question = pages[p_index].questions[q_posi];

				var $q_wrap = $('<div />');
				$q_wrap.addClass("q_wrap");
				$q_wrap.attr({id: question._id});
				$q_wrap.data("numb", q_numb);

				var $btp = $('<h2 />');
				$btp.addClass("blue-title pt20");
				if(first){
					$btp.html("如果用户选择......<i>（注：样本答题时所选的选项包括所有的勾选选项）</i>");
					first = false;
				}
				else
					$btp.text("且选择......");

				var $title = $('<h1 />');
				$title.addClass("title");
				$title.text(question.content.text);
				var $span = $('<span />');
				$span.text((Number(q_numb) + 1) + ".");
				$span.prependTo($title);

				var $fuzzy = $('<span />');
				$fuzzy.addClass("fuzzy");
				var $fuzzy_lab = $('<label />');
				$fuzzy_lab.text(" 模糊匹配");
				var $finp = $('<input type="checkbox" name="fuzzy"/>');
				if(is_update) {
					var conditions = current_logic.conditions;		
					for(var c = 0; c < conditions.length; c ++) {
						if((question._id == conditions[c].question_id) && (conditions[c].answer != null)) {
							if(conditions[c].fuzzy) {
								$finp.attr("checked", true);
							};
						}
					}
				};
				$finp.prependTo($fuzzy_lab);
				$fuzzy_lab.appendTo($fuzzy);


				var $ll = $('<ul />');
				$ll.addClass("logics-list");
				for(var i = 0; i < question.issue.items.length; i ++){
					var $li = $('<li />');
					if(i == 0)
						$li.addClass("l")
					else
						$li.addClass("l m120");
					var $item_lab = $('<label />');
					$item_lab.text(question.issue.items[i].content.text);
					var $inp = $('<input type="checkbox" />');
					$inp.addClass("l");
					$inp.attr({name: question._id});
					$inp.data("id", question.issue.items[i].id);
					if(is_update) {
						var conditions = current_logic.conditions;
						for(var c = 0; c < conditions.length; c ++) {
							if((question._id == conditions[c].question_id) && (conditions[c].answer != null)) {
								for(var k = 0; k < conditions[c].answer.length; k ++) {
									if($inp.data("id") == conditions[c].answer[k])
										$inp.attr("checked", true);
								}
							}
						}
					};
					$inp.prependTo($item_lab);
					$item_lab.appendTo($li);				
					$li.appendTo($ll);
				};
				if(question.issue.other_item.has_other_item) {	//has other item
					var $other = $('<li />');
					$other.addClass("l m120");
					var $other_lab = $('<label />');
					$other_lab.text(question.issue.other_item.content.text);
					var $inp = $('<input type="checkbox" />');
					$inp.addClass("l");
					$inp.attr({name: question._id});
					$inp.data("id", question.issue.other_item.id);
					if(is_update) {
						var conditions = current_logic.conditions;
						for(var c = 0; c < conditions.length; c ++) {
							if((question._id == conditions[c].question_id) && (conditions[c].answer != null)) {
								for(var k = 0; k < conditions[c].answer.length; k ++) {
									if($inp.data("id") == conditions[c].answer[k])
										$inp.attr("checked", true);
								}
							}
						}
					};					
					$inp.prependTo($other_lab);
					$other_lab.appendTo($other);
					$other.appendTo($ll);
				};
				$btp.appendTo($q_wrap);
				$title.appendTo($q_wrap);
				$fuzzy.appendTo($q_wrap);
				$ll.appendTo($q_wrap);
				$q_wrap.appendTo($llm);
			};
		});
		if(count == 0) {		//none is checked
			$.od.odPopup({
				content: '<p class="mt10 ml10 f6">请选择问题</p>',
				size:{width:150,height:100,titleHeight:15}
			});
			return;
		};
		var $btpl = $('<h2 />');
		$btpl.addClass("blue-title pr20 l");
		$btpl.text("......则用户");
		var $sd = $('<select id="logic-ruleType"/>');
		$sd.addClass("dropdown l");
		var $op1 = $('<option value="0"/>');
		$op1.text("停止答题");
		var $op2 = $('<option value="1"/>');
		$op2.text("问题显示");
		var $op3 = $('<option value="2"/>');
		$op3.text("问题隐藏");
		var $op4 = $('<option value="3" />');
		$op4.text("选项显示");	
		var $op5 = $('<option value="4"/>');
		$op5.text("选项隐藏");
		var $fix = $('<div />');
		$fix.addClass("fix");
		$op1.appendTo($sd);$op2.appendTo($sd);$op3.appendTo($sd);$op4.appendTo($sd);$op5.appendTo($sd);
		if(is_update)
			$sd.val(current_logic.rule_type);
		$btpl.appendTo($llm);$sd.appendTo($llm);$fix.appendTo($llm);			
		$llm.appendTo($qw);
		$stw.appendTo('#logic-checked');$qw.appendTo('#logic-checked');$sbw.appendTo('#logic-checked');
		$("#logic-questions").css("display", "none");
		$("#logic-nextbtn").css("display", "none");
		$("#logic-checked").css("display", "block");		
		$("#logic-bkcmbtn").css("display", "block");
	});

	//button 1
	$('#back_btn button').click(function() {
		$("#intr").show();
		$("#logic-checked").empty();
		$("#logic-checked").css("display", "none");
		$("#logic-bkcmbtn").css("display", "none");
		$("#logic-questions").css("display", "block");
		$("#logic-nextbtn").css("display", "block");
	});

	$('#confirm_btn button').click(function() {
		logic = {					//(re)-initialize
			rule_type: null,
			conditions: [],
			result: []
		};
		var ruleType = $("#logic-ruleType").val();
		logic.rule_type = ruleType;

		var flag = false;

		$(".q_wrap").each(function() {
			var condition = {
				question_id: null,
				answer: [],
				fuzzy: false
			};
			condition.question_id = $(this).attr("id");

			var $fuzzy = $(this).find("input").filter(function(index) {return $(this).attr("name") == "fuzzy"});
			condition.fuzzy = $fuzzy.attr("checked") ? true : false;

			var $answers = $(this).find("input").filter(function(index) {return $(this).attr("name") == condition.question_id;});
			$answers.each(function() {
				if(this.checked) {
					condition.answer.push($(this).data("id"));
				};
			});
			if(condition.answer.length == 0) {
				var message = "请选择问题" + (Number($(this).data("numb")) + 1) + "的选项";
				flag = true;
				$.od.odPopup({
					content: '<p class="mt10 ml10 f6">' + message + '</p>',
					size:{width:150,height:100,titleHeight:15}
				});
				return;
			};
			logic.conditions.push(condition);			
		});

		if(flag)
			return;

		$("#logic-checked input").attr("disabled", true);
		$("#logic-checked select").attr("disabled", true);

		switch(ruleType) {
			case "0":
				$("#logic-bkcmbtn button").attr("disabled", "disabled");
				if(is_update) {
					$.putJSON(
						'/questionaires/' + window.survey_id + '/logics/' + current_index + '.json',
						{
							logic: logic
						},
						function(retval) {
							$("#logic-bkcmbtn button").removeAttr("disabled");
							if(retval.success) {
								$.od.odPopup({title: "提示", content: "更新成功！", confirm: function(){
									window.location = '/questionaires/' +	window.survey_id + '/logics';
								}});	
							} else {
								$.od.odPopup({title: "提示", content: "更新出错 :(.<br/>错误代码：" + retval.value.error_code});
							}
						}						
					);
				} else {
					$.postJSON(
						'/questionaires/' + window.survey_id + '/logics.json',
						{
							logic: logic
						},
						function(retval) {
							$("#logic-bkcmbtn button").removeAttr("disabled");
							if(retval.success) {
								$.od.odPopup({title: "提示", content: "更新成功！", confirm: function(){
									window.location = '/questionaires/' +	window.survey_id + '/logics';
								}});
							} else {
								$.od.odPopup({title: "提示", content: "更新出错 :(.<br/>错误代码：" + retval.value.error_code});
							}
						}
					);
				};
				return;
				break;
			case "1":
			case "2":
				renderRs(position, ruleType);
				break;
			case "3":
			case "4":
				renderRs(position, ruleType);
				break;
		};
		$("#logic-bkcmbtn").css("display", "none");
		$("#logic-bkcmbtn2").css("display", "block");

		//results-checkbox
		$(".results-checkbox").click(function() {		//if this event happen, rule_type cannot be 0
			if(this.checked) {
				if(logic.rule_type == "3" || logic.rule_type == "4") {
					var p_index = $(this).data("question").page;
					var q_posi = $(this).data("question").posi;
					var question = pages[p_index].questions[q_posi];
					var $r_items = $('<table class="result-items" />');

					var column = 2;
					var last_i = 0;		//indicate the last i
					var last_j = column - 1;
					var len = question.issue.items.length;
					for(var i = 0; i < len; i += column) {
						last_i = i;
						var $tr = $('<tr />');
						for(var j = 0; j < column; j ++){
							if((i + j) < len) {
								var $td = $('<td />');
								var $item_lab = $('<label />');
								$item_lab.text(question.issue.items[i+j].content.text);
								var $inp = $('<input type="checkbox" />');
								$inp.addClass("items-checkbox l");
								$inp.attr({name: question._id});
								$inp.data("id", question.issue.items[i+j].id);
								$inp.prependTo($item_lab);
								$item_lab.appendTo($td);					
							};
							$td.appendTo($tr);
						};
						$tr.appendTo($r_items);			
					};
					if(question.issue.other_item != undefined && question.issue.other_item.has_other_item) {
						var $td = $('<td />');
						var $other_lab = $('<label />');
						$other_lab.text(question.issue.other_item.content.text);
						var $inp = $('<input type="checkbox" />');
						$inp.addClass("items-checkbox l");
						$inp.attr({name: question._id});
						$inp.data("id", question.issue.other_item.id);
						$inp.prependTo($other_lab);
						$other_lab.appendTo($td);
						if((last_i + last_j) < (len - 1)) {		//the last row isn't full, put other_item there
							$td.appendTo($r_items.find("tr").last());								
						} else {								//make a new row
							var $tr = $('<tr />');
							$td.appendTo($tr);
							$tr.appendTo($r_items);
						}
					};

					$r_items.appendTo($(this).parent().parent().parent());

					
					if(question.question_type == 1) {		//矩阵选择题

						var $r_rows = $('<table class="result-rows" />');

						var column = 2;
						var last_i = 0;		//indicate the last i
						var last_j = column - 1;
						var len = question.issue.rows.length;
						for(var i = 0; i < len; i += column) {
							last_i = i;
							var $tr = $('<tr />');
							for(var j = 0; j < column; j ++){
								if((i + j) < len) {
									var $td = $('<td />');
									var $mi_lab = $('<label />');
									$mi_lab.text(question.issue.rows[i+j].content.text);
									var $inp = $('<input type="checkbox" />');
									$inp.addClass("rows-checkbox l");
									$inp.attr({name: question._id});
									$inp.data("id", question.issue.rows[i+j].id);
									$inp.prependTo($mi_lab);
									$mi_lab.appendTo($td);					
								};
								$td.appendTo($tr);
							};
							$tr.appendTo($r_rows);			
						};

						$r_rows.appendTo($(this).parent().parent().parent());						
					}
				} 
			} else {
				$(this).parent().parent().parent().find(".result-items").remove();
				$(this).parent().parent().parent().find(".result-rows").remove();
			}
		});
	});	



	//button 2
	$('#back_btn2 button').click(function() {
		$("#css-dotted").remove();
		$("#restrain").remove();
		$("#logic-bkcmbtn").css("display", "block");
		$("#logic-bkcmbtn2").css("display", "none");
		$("#logic-checked input").attr("disabled", false);
		$("#logic-checked select").attr("disabled", false);		
	});

	$('#confirm_btn2 button').click(function() {
		if(logic.rule_type == "1" || logic.rule_type == "2") {
			$(".r_wrap").each(function() {
				var $result = $(this).find(".results-checkbox").filter(function(index) {return $(this).attr("name") == "results-checkbox";});
				if($result.attr("checked")){
					logic.result.push($(this).attr("id"));
				}
			});
			if(logic.result.length == 0) {
				$.od.odPopup({
					content: '<p class="mt10 ml10 f6">请选择问题</p>',
					size:{width:150,height:100,titleHeight:15}
				});
				return;				
			}
		} else if(logic.rule_type == "3" || logic.rule_type == "4") {
			$(".r_wrap").each(function() {
				var $result = $(this).find(".results-checkbox").filter(function(index) {return $(this).attr("name") == "results-checkbox";});
				if($result.attr("checked")){
					var questionID = $(this).attr("id");
					var result = {
						question_id: questionID,
						sub_questions: [],
						items: []
					};
					var $items = $(this).parent().parent().parent().find(".items-checkbox").filter(function(index) {return $(this).attr("name") == questionID;});
					$items.each(function() {
						if($(this).attr("checked")){
							result.items.push($(this).data("id"));
						}
					});
					var $rows = $(this).parent().parent().parent().find(".rows-checkbox").filter(function(index) {return $(this).attr("name") == questionID;});
					$rows.each(function() {
						if($(this).attr("checked")){
							result.sub_questions.push($(this).data("id"));
						}
					});
					logic.result.push(result);
				}
			});
			if(logic.result.length == 0) {
				$.od.odPopup({
					content: '<p class="mt10 ml10 f6">请选择问题</p>',
					size:{width:150,height:100,titleHeight:15}
				});
				return;				
			}
		};

		$("#logic-bkcmbtn2 button").attr("disabled", "disabled");
		if(is_update) {
			$.putJSON(
				'/questionaires/' + window.survey_id + '/logics/' + current_index + '.json',
				{
					logic: logic
				},
				function(retval) {
					$("#logic-bkcmbtn2 button").removeAttr("disabled");
					if(retval.success) {
						$.od.odPopup({title: "提示", content: "更新成功！", confirm: function(){
							window.location = '/questionaires/' +	window.survey_id + '/logics';
						}});		
					} else {
						$.od.odPopup({title: "提示", content: "更新出错 :(.<br/>错误代码：" + retval.value.error_code});
					}
				}
			);	
		} else {
			$.postJSON(
				'/questionaires/' + window.survey_id + '/logics.json',
				{
					logic: logic
				},
				function(retval) {
					$("#logic-bkcmbtn2 button").removeAttr("disabled");
					if(retval.success) {
						$.od.odPopup({title: "提示", content: "保存成功！", confirm: function(){
							window.location = '/questionaires/' +	window.survey_id + '/logics';
						}});	
					} else {
						$.od.odPopup({title: "提示", content: "保存出错 :(.<br/>错误代码：" + retval.value.error_code});
					}
				}
			);			
		};

		
	});	

	function renderQs() {
		var num = 0;

		for(var t = 0; t < pages_len; t ++) {
			renderQ(t);
			if(t != (pages_len - 1)) {
				var $pg = $('<div />');
				$pg.addClass("od-merge-preview");
				var $i = $('<i />');
				$i.addClass("od-merge-line");
				var $b = $('<b />');
				$b.text("分页" + (t+1));
				$i.appendTo($pg);$b.appendTo($pg);
				$pg.appendTo('#logic-questions');
			}
		};

		function renderQ(index) {
			var questions = pages[index].questions;
			var len = questions.length;
			var is_gray = true;

			var $q_page = $('<div />');
			$q_page.addClass("page");

			var $top = $('<div />');
			$top.addClass("seperator top gray");
			$top.appendTo($q_page);
			for(var i = 0; i < len; i ++){
				var question = questions[i];
				var type = quill.helpers.QuestionType.getLabel(question.question_type);
				var content = question.content.text;

				var $qg = $('<div />');
				if(is_gray)
					$qg.addClass("q-render gray")
				else
					$qg.addClass("q-render white");
				var $label = $('<label />');
				var $cb = $('<input type="checkbox" />');
				$cb.addClass("list-check");
				$cb.attr({
					name: "question"
				});
				if(question.question_type != 0)		//not Choice Type
					$cb.attr("disabled", "true");
				if(is_update) {
					var conditions = current_logic.conditions;
					for(var c = 0; c < conditions.length; c ++) {
						if(question._id == conditions[c].question_id) {
							$cb.attr("checked", true);
						}
					}
				};
				$cb.data("question", {
					page: index,
					posi: i,
					numb: num
				});

				var $lt = $('<h2 />');
				$lt.addClass("list-title");
				$lt.text(content).attr('title', content);
				var $qn = $('<b />');
				$qn.addClass("nb");
				$qn.text(num + 1);
				var $qt = $('<b />');
				$qt.addClass("title-name");
				$qt.text(type);
				$qt.prependTo($lt);$qn.prependTo($lt);
				$cb.appendTo($label);$lt.appendTo($label);

				var $sgw = $('<div />');
				if(is_gray)
					$sgw.addClass("seperator gray-white")
				else
					$sgw.addClass("seperator white-gray");			

				if(i != (len -1)) {
					$label.appendTo($qg);$sgw.appendTo($qg);
				} else
					$label.appendTo($qg);
				$qg.appendTo($q_page);

				is_gray = !is_gray;
				num ++;
			};
			var $bottom = $('<div />');
			if(!is_gray)	
				$bottom.addClass("seperator bottom gray")
			else
				$bottom.addClass("seperator bottom white");
			$bottom.appendTo($q_page);

			$q_page.appendTo("#logic-questions");		
		}
	};

	function renderRs(pos, rtyp) {
		var num = 0;
		var is_be5 = true;

		var $cd = $('<i id="css-dotted" />');
		$cd.addClass("css-dotted");
		var $res = $('<div id="restrain" />');
		$res.addClass("restrain");
		for(var i = 0; i < pages_len; i ++) {
			var questions = pages[i].questions;
			for(var j = 0; j < questions.length; j ++) {
				if (num > pos){
					var question = questions[j];
					var type = quill.helpers.QuestionType.getLabel(question.question_type);
					var $r_wrap = $('<div />');
					$r_wrap.addClass("r_wrap");
					$r_wrap.attr({id: question._id});
					var $opt = $('<p />');
					if(is_be5)
						$opt.addClass("optname be5")
					else
						$opt.addClass("optname");
					is_be5 = ! is_be5;
					var $r_label = $('<label />');
					$r_label.text(question.content.text);
					var $inp = $('<input type="checkbox" name="results-checkbox" />');
					if((rtyp == 3 || rtyp == 4) && (question.question_type != 0 && question.question_type != 1 && 
						question.question_type != 11 && question.question_type != 12 && question.question_type != 13 && question.question_type != 17))
						$inp.attr("disabled", true);
					$inp.addClass("results-checkbox l");		//add class tag for future use
					$inp.data("question", {
						page: i,
						posi: j
					});

					if(is_update && (rtyp - 2.5) * (current_logic.rule_type - 2.5) > 0) {
						var result = current_logic.result;	//不同的rule_type下result的结构是不一样的
						switch(current_logic.rule_type) {
							case 1:
							case 2:
								for(var k =0; k < result.length; k ++) {
									if(question._id == result[k])
										$inp.attr("checked", true);
								};
								break;
							case 3:
							case 4:
								for(var k = 0; k < result.length; k ++) {
									if(question._id == result[k].question_id) {
										$inp.attr("checked", true);
										
										//Most codes below are the same with the results-checkbox unfolding render
										//What's different: $inp collide, rename it. judge is_update
										var $r_items = $('<table class="result-items" />');

										var column = 2;
										var last_i = 0;		//indicate the last i
										var last_j = column - 1;
										var items_len = question.issue.items.length;
										for(var ii = 0; ii < items_len; ii += column) {
											last_i = ii;
											var $tr = $('<tr />');
											for(var jj = 0; jj < column; jj ++){
												if((ii + jj) < items_len) {
													var $td = $('<td />');
													var $ui_label = $('<label />');
													$ui_label.text(question.issue.items[ii+jj].content.text);
													var $items = $('<input type="checkbox" />');
													$items.addClass("items-checkbox l");
													$items.attr({name: question._id});
													$items.data("id", question.issue.items[ii+jj].id);
													if(is_update && (result[k].items != null)) {
														for(var p = 0; p < result[k].items.length; p ++) {
															if($items.data("id") == result[k].items[p])
																$items.attr("checked", true);
														}
													};
													$items.prependTo($ui_label);
													$ui_label.appendTo($td);					
												};
												$td.appendTo($tr);
											};
											$tr.appendTo($r_items);			
										};
										if(question.issue.other_item != undefined && question.issue.other_item.has_other_item) {
											var $td = $('<td />');
											var $uo_label = $('<label />');
											$uo_label.text(question.issue.other_item.content.text);
											var $items = $('<input type="checkbox" />');
											$items.addClass("items-checkbox l");
											$items.attr({name: question._id});
											$items.data("id", question.issue.other_item.id);
											if(is_update && (result[k].items != null)) {
												for(var p = 0; p < result[k].items.length; p ++) {
													if($items.data("id") == result[k].items[p])
														$items.attr("checked", true);
												}
											};											
											$items.prependTo($uo_label);
											$uo_label.appendTo($td);
											if((last_i + last_j) < (items_len - 1)) {		//the last row isn't full, put other_item there
												$td.appendTo($r_items.find("tr").last());								
											} else {								//make a new row
												var $tr = $('<tr />');
												$td.appendTo($tr);
												$tr.appendTo($r_items);
											}
										};

										$r_items.appendTo($r_wrap);

										
										if(question.question_type == 1) {		//矩阵选择题

											var $r_rows = $('<table class="result-rows" />');

											var column = 2;
											var last_i = 0;		//indicate the last i
											var last_j = column - 1;
											var rows_len = question.issue.rows.length;
											for(var ii = 0; ii < rows_len; ii += column) {
												last_i = ii;
												var $tr = $('<tr />');
												for(var jj = 0; jj < column; jj ++){
													if((ii + jj) < rows_len) {
														var $td = $('<td />');
														var $um_label = $('<label />');
														$um_label.text(question.issue.rows[ii+jj].content.text);
														var $rows = $('<input type="checkbox" />');
														$rows.addClass("rows-checkbox l");
														$rows.attr({name: question._id});
														$rows.data("id", question.issue.rows[ii+jj].id);
														if(is_update && (result[k].sub_questions != null)) {
															for(var p = 0; p < result[k].sub_questions.length; p ++) {
															if($rows.data("id") == result[k].sub_questions[p])
																$rows.attr("checked", true);
															}
														};
														$rows.prependTo($um_label);
														$um_label.appendTo($td);					
													};
													$td.appendTo($tr);
												};
												$tr.appendTo($r_rows);			
											};

											$r_rows.appendTo($r_wrap);						
										}
										//Most codes above are the same with the results-checkbox unfolding render

									};
								};
								break;
						}
					};

					var $bn = $('<b />');
					$bn.addClass("f16 b p110 pr10 g3");
					$bn.text(num+1);
					$bn.prependTo($r_label);$inp.prependTo($r_label);
					var $bt = $('<b />');
					$bt.addClass("f12 g9");
					$bt.text("（" + type + "）");
					$bt.appendTo($r_label);
					$r_label.appendTo($opt);
					$opt.prependTo($r_wrap);
					$r_wrap.appendTo($res);
				};
				num++;
			}
		};
		$cd.appendTo(".logic-list-main");$res.appendTo(".logic-list-main");
	};


});