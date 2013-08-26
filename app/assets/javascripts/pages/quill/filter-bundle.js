//=require ui/widgets/od_popup
//=require quill/helpers

jQuery(function($) {
	var pages = window.survey_questions.pages;
	var pages_len = pages.length;
	var current_filter = window.current_filter;
	var current_index = window.current_index;
	var is_update = (current_filter != null);
	var filter = {};
	renderQs();

	$('#next_btn button').click(function() {
		var $top = $('<div />');
		$top.addClass("seperator top gray");

		var $caption = $('<div />');
		$caption.addClass("q-render gray");
		var $tbf = $('<h2 />');
		$tbf.addClass("title b f14");
		$tbf.text("筛选器设置");
		var $i = $('<i style="margin-left:3px" />');
		$i.addClass("css-white-gray");
		$tbf.appendTo($caption);
		$i.appendTo($caption);
		$top.appendTo("#filter-checked");
		$caption.appendTo("#filter-checked");

		var $qt = $('<div />');
		$qt.addClass("q-render tintgray");
		var $llm = $('<div />');
		$llm.addClass("logic-list-main");

		var $questions = $("input").filter(function(index) {return $(this).attr("name") == "question";});
		var first = true;
		var count = 0;
		$questions.each(function() {
			if(this.checked) {
				count++;
				var p_index = $(this).data("question").page;
				var q_posi = $(this).data("question").posi;
				var q_numb = $(this).data("question").numb;

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

				var $ll = $('<ul />');
				$ll.addClass("logics-list");
				for(var i = 0; i <question.issue.items.length; i ++) {
					var $li = $('<li />');
					$li.addClass("l");
					var $item_lab = $('<label />');
					$item_lab.text(question.issue.items[i].content.text);
					var $inp = $('<input type="checkbox" />');
					$inp.addClass("l");
					$inp.attr("name", question._id);
					$inp.data("id", question.issue.items[i].id);
					if(is_update) {
						var conditions = current_filter.conditions;
						for(var c = 0; c < conditions.length; c ++) {
							if((question._id == conditions[c].name) && (conditions[c].value != null)) {
								for(var k = 0; k < conditions[c].value.length; k ++) {
									if($inp.data("id") == conditions[c].value[k])
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
					$other.addClass("l");
					var $other_lab = $('<label />');
					$other_lab.text(question.issue.other_item.content.text);
					var $inp = $('<input type="checkbox" />');
					$inp.addClass("l");
					$inp.attr("name", question._id);
					$inp.data("id", question.issue.other_item.id);
					if(is_update) {
						var conditions = current_filter.conditions;
						for(var c = 0; c < conditions.length; c ++) {
							if((question._id == conditions[c].name) && (conditions[c].value != null)) {
								for(var k = 0; k < conditions[c].value.length; k ++) {
									if($inp.data("id") == conditions[c].value[k])
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
				$ll.appendTo($q_wrap);
				$q_wrap.appendTo($llm);
			};
		});
		if(count == 0) {		//none is checked
			$.od.odPopup({
				content: '<p class="mt10 ml10 f6">请选择选项</p>',
				size:{width:150,height:100,titleHeight:15}
			});
			return;
		};
		$llm.appendTo($qt);

		var $bottom = $('<div />');
		$bottom.addClass("seperator bottom tintgray");
		$qt.appendTo("#filter-checked");
		$bottom.appendTo("#filter-checked");

		if(is_update) {
			$("#filter-bkcmbtn").find("input").val(current_filter.name);
		};

		$("#filter-questions").css("display", "none");
		$("#filter-nextbtn").css("display", "none");
		$("#filter-checked").css("display", "block");		
		$("#filter-bkcmbtn").css("display", "block");	

	});
	$('#back_btn button').click(function() {
		$("#filter-checked").empty();
		$("#filter-checked").css("display", "none");
		$("#filter-bkcmbtn").css("display", "none");
		$("#filter-questions").css("display", "block");
		$("#filter-nextbtn").css("display", "block");
	});
	$('#confirm_btn button').click(function() {
		filter = {
			conditions: [],
			name: null
		};

		filter.name = $("#filter-name").val();

		var flag = false;

		$(".q_wrap").each(function() {
			var condition = {
				condition_type: 1,
				name: null,
				value: [],
				fuzzy: false
			};
			condition.name = $(this).attr("id");

			var $values = $(this).find("input").filter(function(index) {return $(this).attr("name") == condition.name;});
			$values.each(function() {
				if(this.checked) {
					condition.value.push($(this).data("id"));
				}
			});
			if(condition.value.length == 0) {
				var message = "请选择问题" + $(this).data("numb") + "的选项";
				flag = true;
				$.od.odPopup({
					content: '<p class="mt10 ml10 f6">' + message + '</p>',
					size:{width:150,height:100,titleHeight:15}
				});
				return;
			};
			filter.conditions.push(condition);
		});

		if(flag)
			return;

		$("#filter-bkcmbtn button").attr("disabled", "disabled");
		if(is_update) {
			$.putJSON(
				'/questionaires/' + window.survey_id + '/filters/' + current_index + '.json',
				{
					filter: filter
				},
				function(retval) {
					$("#filter-bkcmbtn button").removeAttr("disabled");
					if(retval.success) {
						$.od.odPopup({title: "提示", content: "更新成功！", confirm: function(){
							window.location = '/questionaires/' +	window.survey_id + '/filters';
						}});
						
					} else {
						$.od.odPopup({title: "提示", content: "更新出错 :(.<br/>错误代码：" + retval.value.error_code});
					}
				}						
			);
		} else {
			$.postJSON(
				'/questionaires/' + window.survey_id + '/filters.json',
				{
					filter: filter
				},
				function(retval) {
					$("#filter-bkcmbtn button").removeAttr("disabled");
					if(retval.success) {
						$.od.odPopup({title: "提示", content: "保存成功！", confirm: function(){
							window.location = '/questionaires/' +	window.survey_id + '/filters';
						}});
					} else {
						$.od.odPopup({title: "提示", content: "保存出错 :(.<br/>错误代码：" + retval.value.error_code});
					}
				}
			);
		};		
	});	

	function renderQs() {
		var num = 0;	//count sequence

		for(var t=0; t<pages_len; t++) {
			renderQ(t);
			if(t != (pages_len-1)) {
				var $pg = $('<div />');
				$pg.addClass("od-merge-preview");
				var $i = $('<i />');
				$i.addClass("od-merge-line");
				var $b = $('<b />');
				$b.text("分页" + (t+1));
				$i.appendTo($pg);
				$b.appendTo($pg);
				$pg.appendTo('#filter-questions');
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

			for(var i=0; i<len; i++) {
				var question = questions[i];
				var type = quill.helpers.QuestionType.getLabel(question.question_type);

				var $qt = $('<div />');
				if(is_gray)
					$qt.addClass("q-render gray")
				else
					$qt.addClass("q-render tintgray");
				var $label = $('<label />');
				var $lc = $('<input type="checkbox" />');
				$lc.addClass("list-check");
				$lc.attr("name", "question");
				if(question.question_type != 0)		//not Choice Type
					$lc.attr("disabled", true);
				$lc.data("question", {
					page: index,
					posi: i,
					numb: num
				});
				if(is_update) {
					var conditions = current_filter.conditions;
					for(var c=0; c<conditions.length; c++) {
						if(question._id==conditions[c].name) {
							$lc.attr("checked", true);
						}
					}
				};
				var $lt = $('<h2 />');
				$lt.addClass("list-title");
				$lt.text(question.content.text);
				if(i==len-1) {
					$lt.attr("style", "border:none");	
				};				
				var $nb = $('<b />');
				$nb.addClass("nb");
				$nb.text(num+1);
				var $tn = $('<b />');
				$tn.addClass("title-name");
				$tn.text(type);

				$tn.prependTo($lt);
				$nb.prependTo($lt);
				$lc.appendTo($label);
				$lt.appendTo($label);
				$label.appendTo($qt);
				$qt.appendTo($q_page);
				is_gray = !is_gray;
				num++;
			};

			var $bottom = $('<div />');
			if(!is_gray)
				$bottom.addClass("seperator bottom gray")
			else
				$bottom.addClass("seperator bottom tintgray");
			$bottom.appendTo($q_page);
			$q_page.appendTo("#filter-questions");

		}
	}
	
});