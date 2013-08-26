//=require ui/widgets/od_left_icon_button
//=require ui/widgets/od_selector
//=require ui/widgets/od_popup
//=require ui/widgets/od_time_selector
//=require quill/helpers

jQuery(function($) {	
	// selector
	var libtn = $.od.odLeftIconButton({text: '单题分析', icon: 'add'});
	libtn.appendTo('#single_analysis');
	var libtn = $.od.odLeftIconButton({text: '交叉分析', icon: 'add'});
	libtn.appendTo('#cross_analysis');

	var report_mockup = window.report_mockup;		//current report_mockup
	var pages = window.survey_questions.pages;
	var is_be5 = true;
	var cg_show = false;

	/* initialize */
	$("#analysis-list").disableSelection();
	$("#analysis-list").sortable({
		start: function(event, ui) {
			ui.item.data("origin", ui.item.index());
		},

		update: function(event, ui) {
			ui.item.data("component", report_mockup.components[ui.item.data("origin")]);
			report_mockup.components.splice(ui.item.data("origin"), 1);
			report_mockup.components.splice(ui.item.index(), 0, ui.item.data("component"));
			colorRender();
		}
	});	

	$(document).on("click", ".analysis-del", function() {
		var numb = $(this).parent().index();
		report_mockup.components.splice(numb, 1);
		$(this).parent().slideUp("slow", function(){
			$(this).remove();
			colorRender();
		});			
	});

	$(document).on("click", ".time-del", function() {
		$(this).parent().remove();
	});

	$(document).on("click", ".single-time-selector-add", function() {
		var $ntf = $('<div />');
		$ntf.addClass("single-time-format");
		$ntf.insertBefore($(this));
		var $nots = $.od.odTimeSelector({format: $(this).data("questionFormat")});
		$nots.appendTo($ntf);
		var $itd = $('<em title="删除时间点" />');
		$itd.addClass("icon icon-del time-del");
		$itd.appendTo($ntf);
	});	

	$(document).on("click", ".cross-time-selector-add", function() {
		var $ntf = $('<div />');
		$ntf.addClass("cross-time-format");
		$ntf.insertBefore($(this));
		var $nots = $.od.odTimeSelector({format: $(this).data("questionFormat")});
		$nots.appendTo($ntf);
		var $itd = $('<em title="删除时间点" />');
		$itd.addClass("icon icon-del time-del");
		$itd.appendTo($ntf);		
	});

	$(document).on("click", ".item-add", function() {
		var items = $(this).data("items");
		var values = [];
		for(var c = 0; c < items.length; c ++)
			values.push(items[c].content.text);
		var $icn = $('<span class="item-com" />');
		var $icsn = $.od.odSelector({
			values: values
		}).appendTo($icn);
		$icn.insertBefore($(this));
	});
	$(document).on("click", ".items-com-del", function() {
		$(this).parent().remove();
	});

	$(document).on("click", ".single-items-com-add", function() {
		var items = $(this).data("items");
		var values = [];
		for(var c = 0; c < items.length; c ++)
			values.push(items[c].content.text);
		var $ntf = $('<div />');
		$ntf.addClass("single-items-com");
		$ntf.text("合并：");
		var $ic = $('<span class="item-com" />');
		var $ics = $.od.odSelector({
			values: values
		}).appendTo($ic);
		$ic.appendTo($ntf);
		var $ai = $('<span class="item-add" />');
		$ai.data("items", items);
		var $aib = $.od.odLeftIconButton({text: '添加选项', icon: 'add'});
		$aib.appendTo($ai);
		$ai.appendTo($ntf);
		var $icd = $('<em title="删除合并" />');
		$icd.addClass("icon icon-del items-com-del");
		$icd.appendTo($ntf);			

		$ntf.insertBefore($(this));	

	});

	$(document).on("click", ".cross-items-com-add", function() {
		var items = $(this).data("items");
		var values = [];
		for(var c = 0; c < items.length; c ++)
			values.push(items[c].content.text);
		var $ntf = $('<div />');
		$ntf.addClass("cross-items-com");
		$ntf.text("合并：");
		var $ic = $('<span class="item-com" />');
		var $ics = $.od.odSelector({
			values: values
		}).appendTo($ic);
		$ic.appendTo($ntf);
		var $ai = $('<span class="item-add" />');
		$ai.data("items", items);
		var $aib = $.od.odLeftIconButton({text: '添加选项', icon: 'add'});
		$aib.appendTo($ai);
		$ai.appendTo($ntf);
		var $icd = $('<em title="删除合并" />');
		$icd.addClass("icon icon-del items-com-del");
		$icd.appendTo($ntf);			

		$ntf.insertBefore($(this));	

	});

	$(document).on("click", ".cross-items-com-add-target", function() {
		var items = $(this).data("items");
		var values = [];
		for(var c = 0; c < items.length; c ++)
			values.push(items[c].content.text);
		var $ntf = $('<div />');
		$ntf.addClass("cross-items-com-target");
		$ntf.text("合并：");
		var $ic = $('<span class="item-com" />');
		var $ics = $.od.odSelector({
			values: values
		}).appendTo($ic);
		$ic.appendTo($ntf);
		var $ai = $('<span class="item-add" />');
		$ai.data("items", items);
		var $aib = $.od.odLeftIconButton({text: '添加选项', icon: 'add'});
		$aib.appendTo($ai);
		$ai.appendTo($ntf);
		var $icd = $('<em title="删除合并" />');
		$icd.addClass("icon icon-del items-com-del");
		$icd.appendTo($ntf);			

		$ntf.insertBefore($(this));	

	});

	$("#single_analysis").draggable({
		revert: true,
		zIndex: 99
	});
	$("#cross_analysis").draggable({
		revert: true,
		zIndex: 99
	});	

	$("#title").val(report_mockup.title);
	$("#author").val(report_mockup.author);
	$("#header").val(report_mockup.header);
	$("#footer").val(report_mockup.footer);

	emptyRender();
	cg_show = true;
	/* initialize end */


	$("#single_analysis").click(function() {
		singlePopup(report_mockup.components.length - 1);
	});

	$("#cross_analysis").click(function() {
		crossPopup(report_mockup.components.length - 1);
	});

	$("#confirm").click(function() {
		var isReturn = false;
		$(".NumberBlank .single-number-format").each(function() {
			var $single_input = $(this).find("input");
			var single_index = $(this).parent().index();
			if($single_input.val() != "") {
				var single_format = $single_input.val().split(/[,，]/);
				for(var i = 0; i < single_format.length; i ++) {
					if(single_format[i] == "" || isNaN(single_format[i])) {
						$single_input.addClass("error");
						$.od.odPopup({
							content: '<p class="mt10 ml10 f6">请输入正确的区段划分</p>'
						});
						isReturn = true;
						break;
					}
				};
				if(!isReturn)
					report_mockup.components[single_index].value.format["-1"] = single_format;
			};	
		});
		$(".NumberBlank .cross-number-format").each(function() {
			var $cross_input = $(this).find("input");
			var cross_index = $(this).parent().index();
			if($cross_input.val() != "") {
				var cross_format = $cross_input.val().split(/[,，]/);
				for(var i = 0; i < cross_format.length; i ++) {
					if(cross_format[i] == "" || isNaN(cross_format[i])) {
						$cross_input.addClass("error");
						$.od.odPopup({
							content: '<p class="mt10 ml10 f6">请输入正确的区段划分</p>'
						});
						isReturn = true;
						break;
					}	
				};
				if(!isReturn)
					report_mockup.components[cross_index].value.target.format["-1"] = cross_format;
			};
		});
		$("#analysis-list .ComboBlank").each(function() {
			var combo_index = $(this).index();
			$(".single-number-format", this).each(function() {
				var $single_input = $(this).find("input");
				var item_id = $(this).parent().data("id");
				if($single_input.val() != "") {
					var single_format = $single_input.val().split(/[,，]/);
					for(var i = 0; i < single_format.length; i ++) {
						if(single_format[i] == "" || isNaN(single_format[i])) {
							$single_input.addClass("error");
							$.od.odPopup({
								content: '<p class="mt10 ml10 f6">请输入正确的区段划分</p>'
							});
							isReturn = true;
							break;
						}
					};
					if(!isReturn)
						report_mockup.components[combo_index].value.format[item_id] = single_format;
				};
			});
			$(".cross-number-format", this).each(function() {
				var $cross_input = $(this).find("input");
				var item_id = $(this).parent().data("id");
				if($cross_input.val() != "") {
					var cross_format = $cross_input.val().split(/[,，]/);
					for(var i = 0; i < cross_format.length; i ++) {
						if(cross_format[i] == "" || isNaN(cross_format[i])) {
							$cross_input.addClass("error");
							$.od.odPopup({
								content: '<p class="mt10 ml10 f6">请输入正确的区段划分</p>'
							});
							isReturn = true;
							break;
						}	
					};
					if(!isReturn)
						report_mockup.components[combo_index].value.target.format[item_id] = cross_format;
				};				
			});
		});	
		if(isReturn)
			return;

		$(".ComboBlank .ComboItem-Time").each(function() {
			if(isReturn)
				return;			
			var combo_index = $(this).parent().index();
			var item_id = $(this).data("id");

			var component_type = report_mockup.components[combo_index].component_type;
			if (component_type == 0)
				report_mockup.components[combo_index].value.format[item_id] = []
			else if (component_type == 1)
				report_mockup.components[combo_index].value.target.format[item_id] = [];

			$(".single-time-format", this).each(function() {
				if(!$(this).children().first().odTimeSelector("checkInput")) {
					$.od.odPopup({
						content: '<p class="mt10 ml10 f6">请选择时间</p>'
					});
					isReturn = true;
					return;
				};
				var single_time = $(this).children().first().odTimeSelector("val");
				report_mockup.components[combo_index].value.format[item_id].push(single_time);				
			});

			$(".cross-time-format", this).each(function() {
				if(!$(this).children().first().odTimeSelector("checkInput")) {
					$.od.odPopup({
						content: '<p class="mt10 ml10 f6">请选择时间</p>'
					});
					isReturn = true;
					return;
				};			
				var cross_time = $(this).children().first().odTimeSelector("val");
				report_mockup.components[combo_index].value.target.format[item_id].push(cross_time);				
			});		
		});
		if(isReturn)
			return;
		$("#analysis-list .TimeBlank").each(function() {
			if(isReturn)
				return;			
			var time_index = $(this).index();

			var component_type = report_mockup.components[time_index].component_type;
			if (component_type == 0)
				report_mockup.components[time_index].value.format["-1"] = []
			else if (component_type == 1)
				report_mockup.components[time_index].value.target.format["-1"] = [];

			$(".single-time-format", this).each(function() {
				if(!$(this).children().first().odTimeSelector("checkInput")) {
					$.od.odPopup({
						content: '<p class="mt10 ml10 f6">请选择时间</p>'
					});
					isReturn = true;
					return;
				};				
				var single_time = $(this).children().first().odTimeSelector("val");
				report_mockup.components[time_index].value.format["-1"].push(single_time);				
			});
		
			$(".cross-time-format", this).each(function() {
				if(!$(this).children().first().odTimeSelector("checkInput")) {
					$.od.odPopup({
						content: '<p class="mt10 ml10 f6">请选择时间</p>'
					});
					isReturn = true;
					return;
				};				
				var cross_time = $(this).children().first().odTimeSelector("val");
				report_mockup.components[time_index].value.target.format["-1"].push(cross_time);				
			});		
		});
		if(isReturn)
			return;

		report_mockup.title = $("#title").val();
		report_mockup.author = $("#author").val();
		report_mockup.header = $("#header").val();
		report_mockup.footer = $("#footer").val();

		$(".single_style").each(function() {
			var index = $(this).parent().index();
			report_mockup.components[index].chart_style = ($(this).children().odSelector("index") - 1 );
		});
		$(".cross_style").each(function() {
			var index = $(this).parent().index();
			if($(this).children().odSelector("index") == 0)
				report_mockup.components[index].chart_style = -1
			else
				report_mockup.components[index].chart_style = ($(this).children().odSelector("index") + 1);
		});

		$("#analysis-list .items-com").each(function() {
			var index = $(this).index();
			report_mockup.components[index].value.items_com = [];
			if(report_mockup.components[index].value.target != undefined)
				report_mockup.components[index].value.target.items_com = [];

			$(".single-items-com", this).each(function() {
				var items = $(this).parent().find(".single-items-com-add").data("items");
				var com = [];
				$(this).find(".item-com").each(function() {
					var item_index = $(this).children().odSelector("index");
					com.push(items[item_index].id);
				});
				report_mockup.components[index].value.items_com.push(com);
			});	

			$(".cross-items-com", this).each(function() {
				var items = $(this).parent().find(".cross-items-com-add").data("items");
				var com = [];
				$(this).find(".item-com").each(function() {
					var item_index = $(this).children().odSelector("index");
					com.push(items[item_index].id);
				});
				report_mockup.components[index].value.items_com.push(com);				
			});	

			$(".cross-items-com-target", this).each(function() {
				var items = $(this).parent().find(".cross-items-com-add-target").data("items");
				var com = [];
				$(this).find(".item-com").each(function() {
					var item_index = $(this).children().odSelector("index");
					com.push(items[item_index].id);
				});
				report_mockup.components[index].value.target.items_com.push(com);					
			});
		});
		
		$(this).attr("disabled", "disabled");
		$.putJSON(
			'/questionaires/' + window.survey_id + '/report_mockups/' + report_mockup._id,
			{
				report_mockup: report_mockup
			},
			function(retval) {
				$("#confirm").removeAttr("disabled");
				if(retval.success) {
					$.od.odPopup({title: "提示", content: "保存成功！", confirm: function(){
						// window.location = '/questionaires/' +	window.survey_id + '/result';
					}});
				} else {
					$.od.odPopup({title: "提示", content: "保存出错 :(.<br/>错误代码：" + retval.value.error_code});
				}
			}
		);			
	});

	function singlePopup(position) {	//Insert after position
		var $psr = $('<div />');
		$psr.addClass("popup-single-row");
		var $dl = $('<dl />');
		var $dt = $('<dt />');
		$dt.addClass("f14 b blue");
		var $lab = $('<label />');
		$lab.text("全选");
		var $inpa = $('<input type="checkbox" id="check-all"/>');
		$inpa.prependTo($lab);
		$lab.appendTo($dt);
		$dt.appendTo($dl);

		var be5 = true;
		var index = 0;
		for(var p = 0; p < pages.length; p ++) {
			var page = pages[p];
			for(var q = 0; q < page.questions.length; q ++) {
				var question = page.questions[q];
				index ++;

				var $dd = $('<dd />');
				if(be5)
					$dd.addClass("be5");
				be5 = !be5;
				var $label = $('<label />');
				var $inp = $('<input type="checkbox" name="question" />');
				$inp.attr("id", question._id);
				var $b = $('<b />');
				$b.addClass("f14 b pl10 pr10 g3");
				$b.text(index);

				$inp.appendTo($label);$b.appendTo($label);$b.append(question.content.text);
				$label.appendTo($dd);
				$dd.appendTo($dl);
			};
		};
		var $obb = $('<button id="single-confirm" />');
		$obb.addClass("od-button b r mt10 mr10");
		$obb.text("确定");
		var $can = $('<button id="single-cancel" />');
		$can.addClass("cancel b r mt10 mr10");
		$can.text("取消");
		$dl.appendTo($psr);$obb.appendTo($psr);$can.appendTo($psr);

		var single_popup = $.od.odPopup({
			type: '',
			title: '单题分析',
			size: {width:620, height:500, titleHeight:20},
			content: $psr
		});

		$("#check-all").click(function() {
			var check_all = this.checked;
			var $question = $(".popup-single-row").find("input").filter(function(index) {return $(this).attr("name") == "question";});
			$question.each(function() {
				$(this).attr("checked", check_all);
			});
		});

		$("#single-confirm").click(function() {
			var $question = $(".popup-single-row").find("input").filter(function(index) {return $(this).attr("name") == "question";});
			var numb = position;
			var count = 0;
			$question.each(function() {
				if(this.checked) {
					count ++;
					var component = {
						component_type: 0,
						value: {
							id: $(this).attr("id"),
							items_com: [],
							format: {
								"-1": []
							}
						},
						chart_style: -1
					};
					report_mockup.components.splice(numb+1, 0, component);
					numb ++;		
				}
			});
			single_popup.odPopup("hide");
			if(position == -1)
				emptyRender()
			else	
				singleInsert(position, position + count);	
		});

		$("#single-cancel").click(function() {
			single_popup.odPopup("hide");
		});		
	};

	function crossPopup(position) {	//Insert after position
		var $ptr = $('<div />');
		$ptr.addClass("popup-two-row mt10");

		var $dl = $('<dl />');
		$dl.addClass("l");
		var $dt = $('<dt />');
		$dt.addClass("f14 b blue");
		$dt.text("选择筛选题");
		$dt.appendTo($dl);

		var be5 = true;
		var index = 0;
		for(var p = 0; p < pages.length; p ++) {
			var page = pages[p];
			for(var q = 0; q < page.questions.length; q ++) {
				var question = page.questions[q];
				index ++;

				if(question.question_type == 0) {		//Choice Type
					var $dd = $('<dd />');
					if(be5)
						$dd.addClass("be5");
					be5 = !be5;
					var $label = $('<label />');
					var $inp = $('<input type="checkbox" name="question" />');
					$inp.attr("id", question._id);
					var $b = $('<b />');
					$b.addClass("f14 b pl10 pr10 g3");
					$b.text(index);

					$inp.appendTo($label);$b.appendTo($label);$b.append(question.content.text);
					$label.appendTo($dd);
					$dd.appendTo($dl);					
				};
			};
		};
		$dl.appendTo($ptr);

		var $dl2 = $('<dl />');
		$dl2.addClass("l ml10");
		var $dt2 = $('<dt />');
		$dt2.addClass("f14 b blue");
		$dt2.text("选择目标题");
		$dt2.appendTo($dl2);	

		be5 = true;
		index = 0;
		for(var p = 0; p < pages.length; p ++) {
			var page = pages[p];
			for(var q = 0; q < page.questions.length; q ++) {
				var question = page.questions[q];
				index ++;

				var $dd2 = $('<dd />');
				if(be5)
					$dd2.addClass("be5");
				be5 = !be5;
				var $label2 = $('<label />');
				var $inp2 = $('<input type="checkbox" name="question2" />');
				$inp2.attr("id", question._id);
				var $b2 = $('<b />');
				$b2.addClass("f14 b pl10 pr10 g3");
				$b2.text(index);

				$inp2.appendTo($label2);$b2.appendTo($label2);$b2.append(question.content.text);
				$label2.appendTo($dd2);
				$dd2.appendTo($dl2);
			};
		};
		$dl2.appendTo($ptr);

		var $obb = $('<button id="cross-confirm" />');
		$obb.addClass("od-button b r mt10 mr10");
		$obb.text("确定");
		var $can = $('<button id="cross-cancel" />');
		$can.addClass("cancel b r mt10 mr10");
		$can.text("取消");
		$obb.appendTo($ptr);$can.appendTo($ptr);					

		var cross_popup = $.od.odPopup({
			type: '',
			title: '交叉分析',
			size: {width:630, height:500, titleHeight:20},
			content: $ptr
		});

		$("#cross-confirm").click(function() {		
			var $question = $(".popup-two-row").find("input").filter(function(index) {return $(this).attr("name") == "question";});
			var $question2 = $(".popup-two-row").find("input").filter(function(index) {return $(this).attr("name") == "question2";});
			var numb = position;
			var count = 0;
			$question.each(function() {
				if(this.checked) {
					var value0 = $(this).attr("id");
					$question2.each(function() {
						if(this.checked) {
							count ++;
							var component2 = {
								component_type: 1,
								value: {
									id: value0,
									items_com: [],
									target: {
										id: $(this).attr("id"),
										items_com: [],
										format: {
											"-1": []
										}
									}
								},
								chart_style: -1
							};
							report_mockup.components.splice(numb+1, 0, component2);
							numb ++;
						}
					});			
				}
			});			
			cross_popup.odPopup("hide");
			if(position == -1)
				emptyRender()
			else				
				crossInsert(position, position + count);				
		});

		$("#cross-cancel").click(function() {
			cross_popup.odPopup("hide");
		});		
	};

	function colorGradient(start, end) {
		if(cg_show) {
			for(var j = (start+1); j <= end; j ++) {
				$("#analysis-list dt").eq(j).css("background-color", "#FFC000");
				$("#analysis-list dt").eq(j).animate({backgroundColor: "#FFFFFF"}, 1200, function(){$(this).removeAttr("style");});
			};		
		}
	};

	function colorRender() {
		$("#analysis-list dt").removeAttr("style");
		is_be5 = true;
		var dt_len = $("#analysis-list dt").length;
		for(var k = 0; k < dt_len; k ++) {
			if(is_be5)
				$("#analysis-list dt").eq(k).addClass("be5");
			else
				$("#analysis-list dt").eq(k).removeClass("be5");
			is_be5 = !is_be5;
		};		
	};

	function singleInsert(start, end) {	//Insert report_mockup[start+1,...,end] after to position start
		for(var i = (start+1); i <= end; i ++) {
			var index = 0;
			var flag = false;
			var currentQ = null;

			for(var p = 0; p < pages.length; p ++) {
				var page = pages[p];
				for(var q = 0; q < page.questions.length; q ++) {
					var question = page.questions[q];
					index ++;
					if(question._id == report_mockup.components[i].value.id) {
						currentQ = question;
						flag = true;
						break;
					};
				};
				if(flag)
					break;
			};

			var $dt = $('<dt />');

			var $button = $('<button />');
			$button.addClass("drag_btn");
			var $fbp = $('<b />');
			$fbp.addClass("f14 b pl10 pr10 g3");
			$fbp.text(index);
			var $fg = $('<b />');
			$fg.addClass("f12 g9");
			$fg.text("（" + quill.helpers.QuestionType.getLabel(currentQ.question_type) + "）");
			var $st = $('<span class="single_style" />');
			var dd_single = $.od.odSelector({
				values: ['所有类型图', '饼图', '圆环图', '折线图', '柱状图', '条形图', '表格'],
				width: 100,
				index: report_mockup.components[i].chart_style + 1
			}).appendTo($st);
			var $iid = $('<em title="删除"/>');
			$iid.addClass("icon icon-del r analysis-del");
			$button.appendTo($dt);$fbp.appendTo($dt);$fbp.append(currentQ.content.text);$fg.appendTo($dt);$st.appendTo($dt);$iid.appendTo($dt);

			if(currentQ.question_type == 3) {	//NumberBlank
				$dt.addClass("NumberBlank");
				var $nf = $('<div />');
				$nf.addClass("single-number-format");
				var $ns = $('<span />');
				$ns.text("请输入区段划分(以逗号隔开)：");
				var $ninp = $('<input type="text" name="number-format" />');
				$ninp.val(report_mockup.components[i].value.format["-1"].join(","));
				$ns.appendTo($nf);$ninp.appendTo($nf);
				$nf.appendTo($dt);

				$("#analysis-list dt").eq(i-1).after($dt);				
			} else if(currentQ.question_type == 7) {	//TimeBlank
				$dt.addClass("TimeBlank");
				var $add = $('<div class="single-time-selector-add" />');
				$add.data("questionFormat", currentQ.issue.format);
				var $aots = $.od.odLeftIconButton({text: '添加时间区段', icon: 'add'});
				$aots.appendTo($add);

				var timeFormat = report_mockup.components[i].value.format["-1"];
				if(timeFormat == undefined || timeFormat.length == 0) {
					$add.appendTo($dt);
					$("#analysis-list dt").eq(i-1).after($dt);
				} else {
					for(var r = 0; r < timeFormat.length; r ++) {
						var $tf = $('<div />');
						$tf.addClass("single-time-format");
						$tf.appendTo($dt);
						var $ots = $.od.odTimeSelector({format: currentQ.issue.format, value: timeFormat[r]});
						$ots.appendTo($tf);
						var $itd = $('<em title="删除时间点" />');
						$itd.addClass("icon icon-del time-del");
						$itd.appendTo($tf);
					};
					$("#analysis-list dt").eq(i-1).after($dt);
					$add.appendTo($dt);				
				};
			} else if(currentQ.question_type == 9) {	//ComboBlank
				$dt.addClass("ComboBlank");
				for(var r = 0; r < currentQ.issue.items.length; r ++) {
					var currentItem = currentQ.issue.items[r];
					if (currentItem.data_type == "Number") {
						var $item = $('<div />');
						$item.addClass("ComboItem-Number");
						$item.data("id", currentItem.id);
						var $h = $('<h3 />');
						$h.text(currentItem.content.text);

						var $nf = $('<div />');
						$nf.addClass("single-number-format");
						var $ns = $('<span />');
						$ns.text("请输入区段划分(以逗号隔开)：");
						var $ninp = $('<input type="text" name="number-format" />');
						$ninp.val((report_mockup.components[i].value.format[currentItem.id] || []).join(","));

						$ns.appendTo($nf);$ninp.appendTo($nf);
						$h.appendTo($item);$nf.appendTo($item);
						$item.appendTo($dt);							
					} else if (currentItem.data_type == "Time") {
						var $item = $('<div />');
						$item.addClass("ComboItem-Time");
						$item.data("id", currentItem.id);
						var $h = $('<h3 />');
						$h.text(currentItem.content.text);

						var $add = $('<div class="single-time-selector-add" />');
						$add.data("questionFormat", currentItem.properties.format);
						var $aots = $.od.odLeftIconButton({text: '添加时间区段', icon: 'add', width: 120});
						$aots.appendTo($add);

						var currentFormat = report_mockup.components[i].value.format[currentItem.id];
						if(currentFormat == undefined || currentFormat.length == 0) {
							$h.appendTo($item);$add.appendTo($item);
						} else {
							$h.appendTo($item);
							for(var rr = 0; rr < currentFormat.length; rr ++) {
								var $tfr = $('<div />');
								$tfr.addClass("single-time-format");
								$tfr.appendTo($item);
								var $otsr = $.od.odTimeSelector({format: currentItem.properties.format, value: currentFormat[rr]});
								$otsr.appendTo($tfr);
								var $itdr = $('<em title="删除时间点" />');
								$itdr.addClass("icon icon-del time-del");
								$itdr.appendTo($tfr);								
							};
							$add.appendTo($item);				
						};

						$item.appendTo($dt);	
					};	
				};
				$("#analysis-list dt").eq(i-1).after($dt);
			} else if(currentQ.question_type == 0 || currentQ.question_type == 1 || currentQ.question_type == 11 || currentQ.question_type == 12 || currentQ.question_type == 17) {	//Choice, MatrixChoice, ConstSum, Sort, Scale
				$dt.addClass("items-com");
				var $add = $('<div class="single-items-com-add" />');
				var items = [];
				for(var q = 0; q < currentQ.issue.items.length; q ++)
					items.push(currentQ.issue.items[q]);		
				if(currentQ.issue.other_item != undefined && currentQ.issue.other_item.has_other_item)
					items.push(currentQ.issue.other_item);
				$add.data("items", items);	

				var values = [];
				for(var c = 0; c < items.length; c ++)
					values.push(items[c].content.text);					
				var $aots = $.od.odLeftIconButton({text: '添加选项合并', icon: 'add'});
				$aots.appendTo($add);

				var items_com = report_mockup.components[i].value.items_com;
				if(items_com == undefined || items_com.length == 0) {
					$add.appendTo($dt);
				} else {
					for(var r = 0; r < items_com.length; r ++) {
						var $sic = $('<div class="single-items-com" />');
						$sic.text("合并：");
						for(var c = 0; c < items_com[r].length; c ++) {
							for(var e = 0; e < items.length; e ++) {
								if(items_com[r][c] == items[e].id) {
									var $ic = $('<span class="item-com" />');
									var $ics = $.od.odSelector({
										values: values,
										index: e
									}).appendTo($ic);
									$ic.appendTo($sic);								
								};
							}

						};
						var $ai = $('<span class="item-add" />');
						$ai.data("items", items);
						var $aib = $.od.odLeftIconButton({text: '添加选项', icon: 'add'});
						$aib.appendTo($ai);
						$ai.appendTo($sic);
						var $icd = $('<em title="删除合并" />');
						$icd.addClass("icon icon-del items-com-del");
						$icd.appendTo($sic);

						$sic.appendTo($dt);
					};
					$add.appendTo($dt);	
				};
				$("#analysis-list dt").eq(i-1).after($dt);				
			} else {
				$("#analysis-list dt").eq(i-1).after($dt);
			};		
		};

		colorGradient(start, end);
		colorRender();
		$("#analysis-list dt").droppable({
			accept: ".draggable",
			over: function(event, ui) {
				var $i = $('<i />');
				$i.addClass("analysis-line");
				$(this).append($i);
			},
			out: function(event, ui) {
				$(this).find(".analysis-line").remove();
			},
			drop: function(event, ui) {
				if(ui.draggable.attr("id") == "single_analysis")
					singlePopup($(this).index())
				else if(ui.draggable.attr("id") == "cross_analysis")
					crossPopup($(this).index());
				$(this).find(".analysis-line").remove();
			}

		});		
	};

	function crossInsert(start, end) {	//Insert report_mockup[start+1,...,end] after to position start
		for(var i = (start+1); i <= end; i ++) {
			var index = [0, 0];
			var flag = [false, false];
			var currentQ = [null, null];

			for(var p = 0; p < pages.length; p ++) {
				var page = pages[p];
				for(var q = 0; q < page.questions.length; q ++) {
					var question = page.questions[q];
					if(!flag[0])	//还没找到
						index[0] ++;
					if(!flag[0] && question._id == report_mockup.components[i].value.id) {		//之前没有找到，现在找到了
						currentQ[0] = question;
						flag[0] = true;
					};
					if(!flag[1])	//还没找到
						index[1] ++;
					if(!flag[1] && question._id == report_mockup.components[i].value.target.id) {		//之前没有找到，现在找到了
						currentQ[1] = question;
						flag[1] = true;
					};
					if(flag[0] && flag[1])		//都找到了
						break;				
				};
				if(flag[0] && flag[1])
					break;
			};

			var $dt = $('<dt />');

			var $button = $('<button />');
			$button.addClass("drag_btn");
			var $fbp = $('<b />');
			$fbp.addClass("f14 b pl10 pr10 g3");
			$fbp.text(index[0]);

			var $ic = $('<em />');
			$ic.addClass("icon-cross");
			var $fbppr = $('<b />');
			$fbppr.addClass("f14 b pl10 pr10 g3");
			$fbppr.text(index[1]);
			var $iid = $('<em />');
			$iid.addClass("icon icon-del r analysis-del");
			var $ct = $('<span class="cross_style" />');
			var dd_cross = $.od.odSelector({
				values: ['所有类型图', '折线图', '柱状图', '条形图', '表格'],
				width: 100
			}).appendTo($ct);
			if(report_mockup.components[i].chart_style == -1)
				dd_cross.odSelector("index", 0)
			else
				dd_cross.odSelector("index", report_mockup.components[i].chart_style - 1);
			$button.appendTo($dt);$fbp.appendTo($dt);$fbp.append(currentQ[0].content.text);$ic.appendTo($dt);$fbppr.appendTo($dt);$fbppr.append(currentQ[1].content.text);$ct.appendTo($dt);$iid.appendTo($dt);

			$dt.addClass("items-com");
			var $adc = $('<div class="cross-items-com-add" />');		
			var items = [];
			for(var q = 0; q < currentQ[0].issue.items.length; q ++)
				items.push(currentQ[0].issue.items[q]);		
			if(currentQ[0].issue.other_item != undefined && currentQ[0].issue.other_item.has_other_item)
				items.push(currentQ[0].issue.other_item);

			$adc.data("items", items);
			var values = [];
			for(var c = 0; c < items.length; c ++)
				values.push(items[c].content.text);					
			var $aotc = $.od.odLeftIconButton({text: '添加选项合并', icon: 'add'});
			$aotc.appendTo($adc);		

			var items_com = report_mockup.components[i].value.items_com;
			if(items_com == undefined || items_com.length == 0) {
				$adc.appendTo($dt);
			} else {
				for(var r = 0; r < items_com.length; r ++) {
					var $sic = $('<div class="cross-items-com" />');
					$sic.text("合并：");
					for(var c = 0; c < items_com[r].length; c ++) {
						for(var e = 0; e < items.length; e ++) {
							if(items_com[r][c] == items[e].id) {
								var $ic = $('<span class="item-com" />');
								var $ics = $.od.odSelector({
									values: values,
									index: e
								}).appendTo($ic);
								$ic.appendTo($sic);								
							};
						}
					};
					var $ai = $('<span class="item-add" />');
					$ai.data("items", items);
					var $aib = $.od.odLeftIconButton({text: '添加选项', icon: 'add'});
					$aib.appendTo($ai);
					$ai.appendTo($sic);
					var $icd = $('<em title="删除合并" />');
					$icd.addClass("icon icon-del items-com-del");
					$icd.appendTo($sic);

					$sic.appendTo($dt);
				};
				$adc.appendTo($dt);	
			};
			
			if(currentQ[1].question_type == 3) {	//NumberBlank
				$dt.addClass("NumberBlank");
				var $nf = $('<div />');
				$nf.addClass("cross-number-format");
				var $ns = $('<span />');
				$ns.text("请输入区段划分(以逗号隔开)：");
				var $ninp = $('<input type="text" name="number-format" />');
				$ninp.val(report_mockup.components[i].value.target.format["-1"].join(","));
				$ns.appendTo($nf);$ninp.appendTo($nf);
				$nf.appendTo($dt);

				$("#analysis-list dt").eq(i-1).after($dt);				
			} else if(currentQ[1].question_type == 7) {	//TimeBlank
				$dt.addClass("TimeBlank");
				var $add = $('<div class="cross-time-selector-add" />');
				$add.data("questionFormat", currentQ[1].issue.format);
				var $aots = $.od.odLeftIconButton({text: '添加时间区段', icon: 'add', width: 120});
				$aots.appendTo($add);

				var timeFormat = report_mockup.components[i].value.target.format["-1"];
				if(timeFormat == undefined || timeFormat.length == 0) {
					$add.appendTo($dt);
					$("#analysis-list dt").eq(i-1).after($dt);
				} else {
					for(var r = 0; r < timeFormat.length; r ++) {
						var $tf = $('<div />');
						$tf.addClass("cross-time-format");
						$tf.appendTo($dt);
						var $ots = $.od.odTimeSelector({format: currentQ[1].issue.format, value: timeFormat[r]});
						$ots.appendTo($tf);
						var $itd = $('<em title="删除时间点" />');
						$itd.addClass("icon icon-del time-del");
						$itd.appendTo($tf);						
					};
					$("#analysis-list dt").eq(i-1).after($dt);
					$add.appendTo($dt);				
				};
			} else if(currentQ[1].question_type == 9) {	//ComboBlank
				$dt.addClass("ComboBlank");
				for(var r = 0; r < currentQ[1].issue.items.length; r ++) {
					var currentItem = currentQ[1].issue.items[r];
					if (currentItem.data_type == "Number") {
						var $item = $('<div />');
						$item.addClass("ComboItem-Number");
						$item.data("id", currentItem.id);
						var $h = $('<h3 />');
						$h.text(currentItem.content.text);

						var $nf = $('<div />');
						$nf.addClass("cross-number-format");
						var $ns = $('<span />');
						$ns.text("请输入区段划分(以逗号隔开)：");
						var $ninp = $('<input type="text" name="number-format" />');
						$ninp.val((report_mockup.components[i].value.target.format[currentItem.id] || []).join(","));

						$ns.appendTo($nf);$ninp.appendTo($nf);
						$h.appendTo($item);$nf.appendTo($item);
						$item.appendTo($dt);							
					} else if (currentItem.data_type == "Time") {
						var $item = $('<div />');
						$item.addClass("ComboItem-Time");
						$item.data("id", currentItem.id);
						var $h = $('<h3 />');
						$h.text(currentItem.content.text);

						var $add = $('<div class="cross-time-selector-add" />');
						$add.data("questionFormat", currentItem.properties.format);
						var $aots = $.od.odLeftIconButton({text: '添加时间区段', icon: 'add', width: 120});
						$aots.appendTo($add);

						var currentFormat = report_mockup.components[i].value.target.format[currentItem.id];
						if(currentFormat == undefined || currentFormat.length == 0) {
							$h.appendTo($item);$add.appendTo($item);
						} else {
							$h.appendTo($item);
							for(var rr = 0; rr < currentFormat.length; rr ++) {
								var $tfr = $('<div />');
								$tfr.addClass("cross-time-format");
								$tfr.appendTo($item);
								var $otsr = $.od.odTimeSelector({format: currentItem.properties.format, value: currentFormat[r]});
								$otsr.appendTo($tfr);
								var $itdr = $('<em title="删除时间点" />');
								$itdr.addClass("icon icon-del time-del");
								$itdr.appendTo($tfr);								
							};
							$add.appendTo($item);				
						};

						$item.appendTo($dt);	
					};			
				};
				$("#analysis-list dt").eq(i-1).after($dt);
			} else if(currentQ[1].question_type == 0 || currentQ[1].question_type == 1 || currentQ[1].question_type == 11 || currentQ[1].question_type == 12 || currentQ[1].question_type == 17) {	//Choice, MatrixChoice, ConstSum, Sort, Scale
				var $add_t = $('<div class="cross-items-com-add-target" />');			
				var items_t = [];
				for(var qt = 0; qt < currentQ[1].issue.items.length; qt ++)
					items_t.push(currentQ[1].issue.items[qt]);		
				if(currentQ[1].issue.other_item != undefined && currentQ[1].issue.other_item.has_other_item)
					items_t.push(currentQ[1].issue.other_item);

				$add_t.data("items", items_t);
				var values_t = [];
				for(var ct = 0; ct < items_t.length; ct ++)
					values_t.push(items_t[ct].content.text);					
				var $aots_t = $.od.odLeftIconButton({text: '添加目标题选项合并', icon: 'add'});
				$aots_t.appendTo($add_t);

				var items_com_t = report_mockup.components[i].value.target.items_com;
				if(items_com_t == undefined || items_com_t.length == 0) {
					$add_t.appendTo($dt);
				} else {
					for(var rt = 0; rt < items_com_t.length; rt ++) {
						var $sic_t = $('<div class="cross-items-com-target" />');
						$sic_t.text("合并：");
						for(var ct = 0; ct < items_com_t[rt].length; ct ++) {
							for(var et = 0; et < items_t.length; et ++) {
								if(items_com_t[rt][ct] == items_t[et].id) {
									var $ic_t = $('<span class="item-com" />');
									var $ics_t = $.od.odSelector({
										values: values_t,
										index: et
									}).appendTo($ic_t);
									$ic_t.appendTo($sic_t);								
								};
							}

						};
						var $ai_t = $('<span class="item-add" />');
						$ai_t.data("items", items);
						var $aib_t = $.od.odLeftIconButton({text: '添加选项', icon: 'add'});
						$aib_t.appendTo($ai_t);
						$ai_t.appendTo($sic_t);
						var $icd_t = $('<em title="删除合并" />');
						$icd_t.addClass("icon icon-del items-com-del");
						$icd_t.appendTo($sic_t);

						$sic_t.appendTo($dt);
					};
					$add_t.appendTo($dt);	
				};
				$("#analysis-list dt").eq(i-1).after($dt);				
			} else {
				$("#analysis-list dt").eq(i-1).after($dt);
			};
		};

		colorGradient(start, end);
		colorRender();
		$("#analysis-list dt").droppable({
			accept: ".draggable",
			over: function(event, ui) {
				var $i = $('<i />');
				$i.addClass("analysis-line");
				$(this).append($i);
			},
			out: function(event, ui) {
				$(this).find(".analysis-line").remove();
			},
			drop: function(event, ui) {
				if(ui.draggable.attr("id") == "single_analysis")
					singlePopup($(this).index())
				else if(ui.draggable.attr("id") == "cross_analysis")
					crossPopup($(this).index());
				$(this).find(".analysis-line").remove();
			}

		});	
	};

	function emptyRender() {
		var $dttemp = $('<dt id="dttemp" />');
		var temp = {
			component_type: 0,
			value: {
				id: "",
				format: {
					"-1": []
				}
			}
		};
		report_mockup.components.splice(0, 0, temp);
		$dttemp.appendTo("#analysis-list");
		for(var n = 1; n < report_mockup.components.length; n ++) {		//components[0] is temp
			if(report_mockup.components[n].component_type == 0) {
				singleInsert(n-1, n);
			} else if(report_mockup.components[n].component_type == 1) {
				crossInsert(n-1, n);
			}
		};
		report_mockup.components.splice(0, 1);
		$("#dttemp").remove();
		colorRender();
	}
});