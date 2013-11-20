//=require ui/widgets/od_white_button
//=require ui/widgets/od_progressbar
//=require ui/widgets/od_waiting
//=require ui/widgets/od_autotip
//=require ui/widgets/od_confirm_tip
//=require ui/widgets/od_popup
//=require ui/plugins/od_button_text
//=require templates/quota_render
//=require templates/quota_editor
//=require templates/quota_editor_q
//=require templates/quota_questions
//=require jquery.numeric
//=require zebra_datepicker

jQuery(function($) {

	/* ===========================
	 * Utility methods
	 * =========================== */
	function error(msg) { $.od.odAutotip({content: msg, style:'error'}); };
	function info(msg) { $.od.odAutotip({content: msg }); };

	/* ===========================
	 * survey publish panels
	 * =========================== */
	var panels = ['close_publish', 'publish'];
	function showPanel(publish_status) {
		var id = null;
		switch(publish_status) {
			case 1: case 4: id = 'close_publish'; break;
			case 2: id = 'publish'; break;
		}
		if(id == null)
			throw 'publish status illegal';
		$('.' + id).show();
		_.each(panels, function(pid) {
			if(pid != id) $('.' + pid).hide();
		});
		if(id == 'publish') {
			$('.head-option').show();
			var plugin = $('.deadline-input').data('Zebra_DatePicker');
			if(plugin)
				plugin.update();
		} else {
			$('.head-option').hide();
		}
	};
	showPanel(window.survey_status);

	/* ===========================
	 * Share and close survey
	 * =========================== */
	// deadline
	var deadline = (window.survey_deadline <= 0) ? null : new Date(window.survey_deadline * 1000);
	var deadline_ipt = $('.deadline-input').val($.util.printDate(deadline));
	function refreshDeadlineInput(date) {
		deadline_ipt.tooltip('destroy');
		deadline_ipt.attr('title', date == null ? '无截止时间' : '将于 ' + ($.util.printDate(date) + ' 23:59:59 自动关闭')).tooltip({
			placement: 'bottom', delay: {show: 300, hide: 0}	
		});
	}
	refreshDeadlineInput(deadline);
	function updateDeadline(date) {
		if(date != null) {
			date.setHours(23);
			date.setMinutes(59);
			date.setSeconds(59);
		}
		refreshDeadlineInput(date);
		$.putJSON(
			'/questionaires/' + window.survey_id + '/deadline.json', { 
				deadline: (date == null) ? -1 : (date.getTime() / 1000)
			}, function(retval) {
				if(!retval.success) {
					error((retval.value.error_code == 'error_110001') ? '截止时间必须大于当前时间' : '设置截止时间失败，请重试');
				}
			}						
		);	
	}
	deadline_ipt.Zebra_DatePicker({
		days: ['日', '一', '二', '三', '四', '五', '六'],
		lang_clear_date: '清除',
		months: ['一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月'],
		direction: [$.util.printDate(new Date()), false],
		onSelect: function(date_format, date_YYYY_MM_DD, dateJS) { updateDeadline(dateJS); },
		onClear: function() { updateDeadline(null); }
	});
	// close
	var close_btn = $('#close_survey').click(function() {
		$.util.disable(close_btn);
		close_btn.odButtonText({ text: '关闭中...'});
		$.putJSON('/questionaires/' + window.survey_id + '/close.json', function(retval) {
			retval.success ? showPanel(1) : error('操作失败');
			$.util.enable(close_btn);
			close_btn.odButtonText('restore');
		});
	});
	// share
	var href = $('#link-address').val();
	var href_ipt = $('#link-address').mouseover(function(e) { $(e.target).select(); });
	$('button.copy-link').click(function() {
		if (window.clipboardData) {	//IE
			window.clipboardData.setData("Text", href);
			$.od.odPopup({ content: '链接已经复制至剪贴板' });
		} else {
			$.od.odPopup({ 
				content: '选择输入框里链接并鼠标右键或按 ctrl+c 进行复制。', 
				close: function() { href_ipt.select(); }
			});
		};	
	});
	// sharing
	_.each(['SinaWeibo', 'TencentWeibo', 'Renren', 'Douban', 'QQSpace', 
		'Kaixin001', 'Diandian', 'Gmail', 'Fetion'], $.proxy(function(v) {
		$('.' + v).click(function() {
			$.social['shareTo' + v](href, '亲，帮忙填写一份问卷哦~');
		});
	}, this));

	/* ===========================
	 * submit survey
	 * =========================== */
	var submit_btn = $('#submit_survey').click(function() {
		$.util.disable(submit_btn);
		submit_btn.odButtonText({ text: '正在提交...'});
		$.putJSON('/questionaires/' + window.survey_id + '/publish.json', function(retval) {
			retval.success ? showPanel(2) : error('操作失败');
			$.util.enable(submit_btn);
			submit_btn.odButtonText('restore');
		});
	});

	/* ===========================
	 * adjust questions
	 * =========================== */
	var questions = _.compact(_.flatten(_.map(window.survey_questions.pages, function(page) {
		return _.map(page.questions, function(q) {
			return (q.question_type == 14) ? null : q;
		});
	})));
	for (var i = 0; i < questions.length; i++) {
		var q = questions[i];
		q.number = $.util.printNumber(i + 1);
		q.title = $.richtext.print(q.content);
	};

	/* ===========================
	 * refresh quotas
	 * =========================== */
	var refresh_btn = $.od.odWhiteButton({icon: 'refresh2'}).appendTo('#refresh_btn');
	refresh_btn.click(function() {
		var waiting_dom = $.od.odWaiting({ type: 2, contentId: '#quotas_con', message: '正在刷新配额...', backColor: '#fff' });
		waiting_dom.odWaiting('open');
		$.postJSON('/questionaires/' + window.survey_id + '/quotas/refresh.json', function(retval) {
			waiting_dom.odWaiting('destroy');
			if(retval.success) {
				window.survey_quota = retval.value;
				setupQuotas();
			} else {
				error('刷新配额失败');
			}
		});
	});

	/* ===========================
	 * Render quota 
	 * =========================== */
	function renderQuota(_index) {
		var quota = window.survey_quota.rules[_index];
		var rules = _.map(quota.conditions, function(cond) {
			var target_q = _.find(questions, function(q) { return (q._id == cond.name); });
			var is_single = (target_q.issue.option_type < 2);
			return {
				number: target_q.number,
				title: $.richtext.print(target_q.content),
				answer: ((is_single || !cond.fuzzy) ? '选择' : '答案包含') + _.compact(_.map(cond.value, function(input_id) {
						var target_item = null;
						if(target_q.issue.other_item.has_other_item && target_q.issue.other_item.id == input_id)
							target_item = target_q.issue.other_item;
						else
							target_item = _.find(target_q.issue.items, function(item) { return item.id == input_id; }); 
						return '“' + (target_item ? $.richtext.print(target_item.content) : null) + '”';
					})).join(is_single ? '，或' : '和') 
			};
		});
		var dom = $(HandlebarsTemplates['quota_render']($.extend({rules: rules}, quota)));
		// progress
		var pctg = ((quota.amount == 0) ? 1 : quota.finished_count/quota.amount);
		if(pctg > 1) pctg = 1;
		var pb = $.od.odProgressbar({ width: 675, value: 0 }).appendTo($('.progress', dom));
		pb.odProgressbar("fixedTimer", 2500 * pctg, 50, false, pctg);
		// delete event
		var del_btn = $('.icon-del', dom);
		var confirm_tip = $.od.odConfirmTip({
			target: del_btn,
			text: '确定删除',
			confirm: function(callback) {
				var index = dom.siblings().length - dom.index();
				$.deleteJSON('/questionaires/' + window.survey_id + '/quotas/' + index + '.json', function(retval) {
					if(retval.success) {
						$('.icons', dom).remove();
						confirm_tip.odConfirmTip('destroy');
						dom.slideUp(function() {
							dom.remove();
							refreshQuotasList();
						});
					} else {
						error('删除配额失败');
					}
					callback(retval.success);
				});
			},
			hide: function() { dom.removeClass('locked'); }
		});
		del_btn.click(function(e) {
			dom.addClass('locked');
			confirm_tip.odConfirmTip('show', e);
		});
		// edit event
		$('.icon-edit', dom).click(function() {
			var index = dom.siblings().length - dom.index();
			renderQuotaEditor(index).insertAfter(dom);
			confirm_tip.odConfirmTip('destroy');
			dom.remove();
			refreshQuotasList();
		});
		return dom;
	};
	function refreshQuotasList() {
		// refresh quotas list indexes
		var dom_list = $('.quotas > li');
		var count = dom_list.length;
		dom_list.each(function(i, v) {
			$('> h4', v).text('配额 ' + $.util.printNumber(count - i));
		});
		$('.quotas >li:last').addClass('last');
	};
	function setupQuotas() {
		$('.quotas').empty();
		$('#total_finished_count').text(window.survey_quota.finished_count);
		for (var i = 0; i < window.survey_quota.rules.length; i++) {
			renderQuota(i).prependTo('.quotas');
		};
		refreshQuotasList();
	};
	setupQuotas();

	/* ===========================
	 * add new quota
	 * =========================== */
	var add_quota_btn = $.od.odWhiteButton({icon: 'add2'}).appendTo('#add_btn');
	add_quota_btn.click(function() {
		var waiting_dom = $.od.odWaiting({ type: 2, contentId: '#quotas_con', message: '正在添加新配额...', backColor: 'transparent' });
		waiting_dom.odWaiting('open');
		var new_quota = { amount: 100, conditions: [] };
		$.postJSON('/questionaires/' + window.survey_id + '/quotas.json', new_quota, function(retval) {
			waiting_dom.odWaiting('destroy');
			if(retval.success) {
				window.survey_quota.rules.push(retval.value);
				var editor = renderQuotaEditor(window.survey_quota.rules.length - 1).prependTo('.quotas');
				_bg_fade_out(editor);
				refreshQuotasList();
			} else {
				error('添加配额失败');
			}
		});
	});

	/* ===========================
	 * edit quota
	 * =========================== */
	function _bg_fade_out(dom) {
		dom.css('backgroundColor', '#ffff99');
		dom.animate({backgroundColor: "transparent"}, 1200, function(){$(this).removeAttr("style");});
	};
	function renderQuotaEditor(_index) {
		var editing_quota = $.extend(true, {}, window.survey_quota.rules[_index]);
		var dom = $(HandlebarsTemplates['quota_editor'](editing_quota));
		// amount input
		$('.amount', dom).numeric({ decimal: false, negative: false }, function() {
			$(this).focus();
		}).blur(function() { editing_quota.amount = parseInt($(this).val()); });
		// render quota questions
		function _render_questions(newly_ids) {
			var qs_con = $('ul.questions', dom).empty();
			_.each(editing_quota.conditions, function(cond) {
				var dom_id = $.util.uid();
				var target_q = _.find(questions, function(q) { return (q._id == cond.name); });
				var is_single = (target_q.issue.option_type < 2);
				var options = _.map(target_q.issue.items, function(item) { 
					return { id: item.id, text: $.richtext.print(item.content) }; 
				});
				if(target_q.issue.other_item.has_other_item) {
					options.push({ id: target_q.issue.other_item.id, text: $.richtext.print(target_q.issue.other_item.content) });
				};
				var dom = $(HandlebarsTemplates['quota_editor_q']({ 
					id: dom_id,
					title: target_q.title,
					single: is_single,
					options: options
				})).appendTo(qs_con);
				// set rule value
				cond.value = cond.value || [];
				_.each(cond.value, function(input_id) {
					$('#' + dom_id + '_' + input_id, dom).attr('checked', 'checked');
				});
				$('.opt', dom).change(function() {
					var input_id = parseFloat($(this).attr('id').split('_')[1]);
					if($(this).is(':checked')) {
						if(!_.contains(cond.value, input_id)) cond.value.push(input_id);
					} else {
						cond.value = _.reject(cond.value, function(v) { return v == input_id });
					}
				});
				// set fuzzy
				if(!is_single) {
					cond.fuzzy ? $('.fuzzy', dom).attr('checked', 'checked') : 
						$('.precise', dom).attr('checked', 'checked');
					$('.fuzzy', dom).change(function() {
						cond.fuzzy = $(this).is(':checked');
					});
					$('.precise', dom).change(function() {
						cond.fuzzy = !$(this).is(':checked');
					});
				}
				// delete button
				$('button', dom).click(function() {
					editing_quota.conditions.splice(dom.index(), 1);
					dom.remove();
				});
				// highlight
				if(_.contains(newly_ids, cond.name))
					_bg_fade_out(dom);
			});
		};
		_render_questions();
		// add question
		$('.add-btn', dom).click(function() {
			var popup_dom = $(HandlebarsTemplates['quota_questions']({ questions: questions }));
			$('li:odd', popup_dom).addClass('bf2');
			_.each(questions, function(q, i) {
				if(q.question_type != 0) {
					$('li:eq(' + i + ')', popup_dom).addClass('disable');
					$.util.disable($('#' + q._id, popup_dom));
				}
			});
			for (var i = 0; i < editing_quota.conditions.length; i++) {
				$('#' + editing_quota.conditions[i].name, popup_dom).attr('checked', 'checked');
			};
			$('button.confirm-btn', popup_dom).click(function() {
				var selected_ids = [];
				$('input', popup_dom).each(function(i, v) {
					if($(v).is(':checked'))
						selected_ids.push($(v).attr('id'));
				});
				var current_ids = _.map(editing_quota.conditions, function(cond) { return cond.name; });
				var newly_ids = _.difference(selected_ids, current_ids);
				var new_conditions = _.map(selected_ids, function(id) {
					var con = _.find(editing_quota.conditions, function(v) { return v.name == id; });
					return (con != null) ? con : { condition_type: 1, name: id, value: [], fuzzy: false };
				});
				editing_quota.conditions = new_conditions;
				_render_questions(newly_ids);
				popup.odPopup('hide');
			});
			$('button.cancel-btn', popup_dom).click(function() {
				popup.odPopup('hide');
			});
			var popup = $.od.odPopup({
				type: null,
				title: '选择配额约束问题（只支持选择题）',
				content: popup_dom,
				size:{width:520, height:500},
			});
		});
		// cancel event
		function _close_editor() {
			var index = dom.siblings().length - dom.index();
			renderQuota(index).insertAfter(dom);
			dom.remove();
			refreshQuotasList();
		}
		$('.cancel-editor', dom).click(_close_editor);
		// confirm event
		$('.confirm-editor', dom).click(function() {
			var index = dom.siblings().length - dom.index();// NOTE: Incorrect to use the parameter index of renderEditor
			if(editing_quota.amount <= 0) {
				error('配额数量必须大于零');
				return;
			}
			var waiting_dom = $.od.odWaiting({ type: 2, contentId: dom, message: '正在保存...', backColor: '#fff' });
			waiting_dom.odWaiting('open');
			$.putJSON('/questionaires/' + window.survey_id + '/quotas/' + index + '.json', {
				quota: editing_quota
			}, function(retval) {
				waiting_dom.odWaiting('destroy');
				if(retval.success) {
					window.survey_quota.rules[index] = retval.value;
					_close_editor();
				} else {
					error('保存配额失败');
				}
			});
		});

		// _bg_fade_out(dom);
		return dom;
	}

});