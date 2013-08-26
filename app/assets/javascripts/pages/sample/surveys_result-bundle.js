//=require jquery.stickyscroll
//=require highcharts
//=require jquery.colorbox
//=require templates/sr_waiting
//=require templates/sr_q
//=require templates/sr_tb
//=require templates/sr_tb_wide
//=require templates/sr_tb_scale
//=require templates/sr_texts
//=require quill/templates/fillers/media_preview
//=require ui/widgets/od_bmap
//=require ui/widgets/od_progressbar
//=require ui/widgets/od_popup

jQuery(function($) {
	// sticky header
	if(!$.browser.msie) {
		$('#sf_menus_sticky').stickyScroll({container: $('#sf_menus')});
	}

	// variables
	var TIME_STEP = 500;

	/* ===========================
	 * Get job progress
	 * =========================== */
	var analysis_waiting_dom = $(HandlebarsTemplates['sr_waiting']({msg: '正在进行结果分析 ... 0%'})).appendTo('#result');
	function _msg(msg) { $('.waiting span', analysis_waiting_dom).text(msg); }
	function startAnalysis(job_id) {
		$.getJSON('/jobs/' + job_id + '.json', function(retval) {
			if(retval.success && retval.value >= 0) {
				_msg('正在进行结果分析 ... ' + Math.round(retval.value * 100) + '%');
				if(retval.value >= 1) {
					analysis_waiting_dom.remove();
					// stat
					$.getJSON('/jobs/' + job_id + '/stats.json', function(retval) {
						if(retval.success) {
							$('.stat-con').text('样本数 ' + retval.value.tot_answer_number);
						}
					});
					// answers
					loadAnswers(job_id, 0, 0);
					// report
					$.util.enable($('.export-con button'));
					$('.export-con button.word').off('click').click(function() {
						exportReport(job_id, 'word');
					});
					$('.export-con button.pdf').off('click').click(function() {
						exportReport(job_id, 'pdf');
					});
					// share
					var title = '我分享了一份调研报告《' + window.survey_title + '》';
					$('.weibo').click(function() {
						$.social.shareToSinaWeibo(location.href, title);
					});
					$('.tengxun').click(function() {
						$.social.shareToTencentWeibo(location.href, title);
					});
				} else {
					setTimeout(function() { startAnalysis(job_id); }, TIME_STEP);
				}
			}
		});
	}
	startAnalysis(window.job_id);

	/* ===========================
	 * Answer analysis
	 * =========================== */
	function renderRichtext(qid, parent, rich_value, size) {
		if(!parent) return;
		if(!rich_value) return;
		parent.append($.richtext.textToHtml(rich_value));
		if(!size) size = 'small';
		_.each(['image', 'video', 'audio'], function(v) {
			if(!rich_value[v]) rich_value[v] = [];
		});
		if(rich_value.image.length + rich_value.video.length + rich_value.audio.length == 0)
			return;
		var media_con = $('<div class="media-preview-con" />');
		_.each(['image', 'video', 'audio'], $.proxy(function(v) {
			medias = rich_value[v];
			for (var i = 0; i < medias.length; i++) {
				var m = medias[i];
				var m_dom = $(HandlebarsTemplates['quill/templates/fillers/media_preview']({
					size: size, 
					type: v, 
					url: $.regex.isUrl(m) ? m : ('/utility/materials/' + m + '/preview')
				}));
				m_dom.appendTo(media_con);
				m_dom.colorbox({
					href: $.regex.isUrl(m) ? m : ('/utility/materials/' + m),
					rel: qid,
					opacity: 0.3,
					current: '<span style="margin-left: 2em;">{current} / {total}</span>',
					close: '关闭',
					previous: '向前',
					next: '向后',
					xhrError: '加载资源出错',
					imgError: '加载图片出错',
					photo: (v == 'image'),
					maxHeight: '500px'
				});
			};
		}, this));
		if(media_con != null)
			parent.append(media_con);
	};
	var SUPPORTED_LABEL_LENGTH = [999, 18, 10, 6, 5, 4, 3];	//SIZE 1, MAX LENGTH 18; SIZE > 6, MAX LENGTH 2
	function _formatter(str, cl, no_format) {
		if(str == undefined || no_format) return str;
		if(cl < SUPPORTED_LABEL_LENGTH.length) {
			if(str.length < SUPPORTED_LABEL_LENGTH[cl])
				return str;
			else
				return str.substr(0, SUPPORTED_LABEL_LENGTH[cl]) + '...';
		} else
			return str.substr(0,2) + '...';
	};
	var COLORS = ['#FFC800', '#5691F0', '#FF4A51', '#9BCA3E', '#9F8CE2', 
		'#FF953E', '#78D5F9', '#F4629A', '#63D3C2', '#BB6EDB', 
		'#FFE632', '#6777E5', '#FF775C', '#6FD165', '#8D50D3'];
	var CHART_DEFAULT_SETTING = {
		title: {text: ''},
		colors: COLORS
	};
	function _getLegend(legend_horizontal) {
		var CHART_DEFAULT_LEGEND = {
			enabled: true,
			borderWidth: 0,
			layout: 'vertical',
			align: 'right',
			verticalAlign: 'middle',
			itemMarginTop: 5,
			itemMarginBottom: 5
		};
		return legend_horizontal ? _.extend({}, CHART_DEFAULT_LEGEND, {
				layout: 'horizontal',
				align: 'center',
				verticalAlign: 'bottom'
			}) : CHART_DEFAULT_LEGEND;
	};
	var GRID_LINE_COLOR = '#dce0e5', Y_LABEL_COLOR = '#868c95', X_LABEL_COLOR = '#666';
	function renderColumn(target_id, categories, series, style) {
		// style: {color_by_point, show_legend, legend_horizontal, x_label_no_format}
		style = style || {};
		var chart = new Highcharts.Chart(_.extend({}, CHART_DEFAULT_SETTING, {
			chart: { renderTo: target_id, type: 'column' },
			legend: _getLegend(style.legend_horizontal),
			xAxis: { 
				categories: categories,
				labels: {
					formatter: function() { 
						return _formatter(this.value, categories.length, style.x_label_no_format);
					},
					style: {color: X_LABEL_COLOR}
				},
				lineColor: GRID_LINE_COLOR,
			},
			yAxis: { 
				title: { text: "" },
				gridLineColor: GRID_LINE_COLOR,
				labels: { style: { color: Y_LABEL_COLOR } }
			},
			plotOptions: {
				column: {
					shadow: false,
					borderWidth: 0,
					showInLegend: style.show_legend || false,
					colorByPoint: style.color_by_point || false,
					dataLabels: {enabled: true}
				}
			},
			series: series
		}));
	};
	function renderPie(target_id, categories, series) {
		var chart = new Highcharts.Chart(_.extend({}, CHART_DEFAULT_SETTING, {
			chart: { renderTo: target_id, type: 'pie' },
			legend: _getLegend(),
			plotOptions: {
				pie: { 
					showInLegend: true,
					shadow: false,
					borderWidth: 2,
					dataLabels: {
						formatter: function() {
							if(this.point.name != undefined) {
								var cl = categories.length;
								if(cl < SUPPORTED_LABEL_LENGTH.length) {
									if(this.point.name.length < SUPPORTED_LABEL_LENGTH[cl])
										return this.point.name + ': ' + this.percentage.toFixed(1) + '%'
									else
										return this.point.name.substr(0, SUPPORTED_LABEL_LENGTH[cl]) + '...' + ': ' + this.percentage.toFixed(1) + '%';
								} else
									return this.point.name.substr(0,2) + '...' + ': ' + this.percentage.toFixed(1) + '%';
							}
						}
					}
				}
			},
			series: series
		}));
	};
	function renderArea(target_id, categories, series, style) {
		// style: {x_label_rotation, x_label_no_format}
		style = style || {};
		var chart = new Highcharts.Chart(_.extend({}, CHART_DEFAULT_SETTING, {
			chart: { renderTo: target_id, type: 'area' },
			xAxis: { 
				categories: categories,
				lineColor: GRID_LINE_COLOR,
				labels: { 
					rotation: (style.x_label_rotation == undefined ? 0 : style.x_label_rotation),
					style: { color: X_LABEL_COLOR },
					formatter: function() { 
						return _formatter(this.value, categories.length, style.x_label_no_format);
					}
				}
			},
			yAxis: { 
				title: { text: "" },
				gridLineColor: GRID_LINE_COLOR,
				labels: { style: { color: Y_LABEL_COLOR } }
			},
			plotOptions: {
				area: {
					shadow: false,
					borderWidth: 2,
					dataLabels: {enabled: true},
					showInLegend: false,
					fillOpacity: 0.4,
					marker: {
						lineWidth: 2,
						fillColor: '#fff',
						lineColor: COLORS[0]
					}
				}
			},
			series: series						
		}));
	};
	function renderBar(target_id, categories, series, style) {
		// style: {stacking, legend_horizontal}
		style = style || {};
		var chart = new Highcharts.Chart(_.extend({}, CHART_DEFAULT_SETTING, {
			chart: { renderTo: target_id, type: 'bar' },
			legend: _getLegend(style.legend_horizontal),
			xAxis: { 
				categories: categories,
				labels: {
					formatter: function() { 
						return _formatter(this.value, categories.length, style.x_label_no_format);
					},
					style: {color: X_LABEL_COLOR}
				},
				lineColor: GRID_LINE_COLOR,
			},
			yAxis: { 
				title: { text: "" },
				gridLineColor: GRID_LINE_COLOR,
				labels: { style: { color: Y_LABEL_COLOR } }
			},
			plotOptions: {
				series: { 
					stacking: style.stacking ? 'normal' : false,
					shadow: false,
					borderWidth: 0,
					dataLabels: {enabled: false}
				}
			},
			series: series
		}));
	};

	function loadAnswers(job_id, page_index, question_index) {
		if(page_index < 0 || page_index >= window.survey_questions.pages.length) return;
		var questions = window.survey_questions.pages[page_index].questions;

		var page_dom = $(HandlebarsTemplates['sr_waiting']({msg: '正在加载调研报告第 ' + (page_index + 1) + ' 页 ...'})).appendTo('#result');
		$.getJSON('/jobs/' + job_id + '/analysis_result.json', { 
			page_index: page_index 
		}, function(retval) {
			if(retval.success) {
				page_dom.empty();
				for (var q_idx = 0; q_idx < questions.length; q_idx++) {
					var q = questions[q_idx], a = retval.value[q._id];
					if(q.question_type == 14) {
						var q_con = $(HandlebarsTemplates['sr_q']({ 
							chart_id: q._id + "_chart"
						})).appendTo(page_dom);
						renderRichtext(q._id, $('.q-title', q_con), q.content);
						$('.q-content', q_con).remove();
					} else {
						question_index++;
						// 1. question container
						var q_con = $(HandlebarsTemplates['sr_q']({ 
							index: question_index,
							chart_id: q._id + "_chart"
						})).appendTo(page_dom);
						renderRichtext(q._id, $('.q-title', q_con), q.content);
						// 2. question content
						// if answer is null, it means that the question is a newly added question
						// and the answer statistic cache has no cache about it 
						if(q.question_type == 0) {
							// Choice
							if(!a) a = [0, {}];
							var items = [];
							for(var m = 0; m < q.issue.items.length; m ++)
								items.push(q.issue.items[m]);
							if(q.issue.other_item.has_other_item) 
								items.push(q.issue.other_item);
							var categories = [], data = [];
							for (var i = 0; i < items.length; i++) {
								categories.push($.richtext.print(items[i].content));
								var a_count = 0;
								if(a[1][items[i].id] != undefined)
									a_count = a[1][items[i].id];
								data.push(a_count);
							};
							// chart 
							if(q.issue.option_type > 1) {
								renderColumn(q._id + '_chart', categories, [{name:'选择人数', data: data}], { color_by_point: true });
							} else {
								renderPie(q._id + '_chart', categories, [{type: 'pie', name: '选择人数', data: _.zip(categories, data) }])
							}
							// table
							var tb_dom = $(HandlebarsTemplates['sr_tb']({ rows: data, total: a[0] })).appendTo($('.table', q_con));
							_.each(items, function(v, i){
								renderRichtext(q._id, $('tr:eq(' + (i+1) + ') td:eq(0)', tb_dom), v.content);
							});
						} else if (q.question_type == 1) {
							// MatrixChoice
							if(!a) a = [0, {}];
							var rows = q.issue.rows || [], items = q.issue.items || [];
							var categories = _.map(rows, function(v){return $.richtext.print(v.content); }), 
								series = _.map(items, function(v) {
									return {
										name: $.richtext.print(v.content),
										data: _.map(rows, function(r) { return (a[1][r.id + "-" + v.id] || 0); })
									};
								});
							// chart
							$('.q-content', q_con).addClass('wide');
							renderColumn(q._id + '_chart', categories, series, { show_legend: true, legend_horizontal: true} );
							// table
							var tb_dom = $(HandlebarsTemplates['sr_tb_wide']({ 
								column_count: items.length,
								row_count: rows.length
							})).appendTo($('.table', q_con));
							$('<div class="tfoot" >（统计每个选项的选择人数）</div>').insertAfter(tb_dom);
							$('tr', tb_dom).each(function() { $('td:last,th:last', $(this)).addClass('tr'); });
							$('tr:last th', tb_dom).addClass('tb');
							_.each(items, function(v, i) {
								renderRichtext(q._id, $('tr:eq(0) th:eq(' + (i + 1) +')', tb_dom), v.content);
							});
							_.each(rows, function(v, i) {
								renderRichtext(q._id, $('tr:eq(' + (i + 1) + ') th:eq(0)', tb_dom), v.content);
							});
							_.each(series, function(s, i) {
								var total = 0;
								_.each(s.data, function(d, k) {
									$('tr:eq(' + (k + 1) + ') td:eq(' + i + ')', tb_dom).text(d);
									total += d;
								});
								$('tr:last th:eq(' + (i + 1) + ')', tb_dom).text(total);
							});
						} else if (q.question_type == 3) {
							// NumberBlank
							if(!a) a = [0, {mean: "", histogram: [], segment: []}];
							var categories = [], data = [];
							for(var i = 0; i < a[1]["histogram"].length; i ++) {	//minimum histogram length: 2
								data.push(a[1]["histogram"][i]);
								if(i == 0)
									categories.push('<=' + a[1]["segment"][i])
								else if(i == a[1]["segment"].length)
									categories.push(">" + a[1]["segment"][i-1])
								else
									categories.push("(" + a[1]["segment"][i-1] + ", " + a[1]["segment"][i] + ']');
							};
							// chart
							renderArea(q._id + '_chart', categories, [{ name: "选择人数", data: data }], {x_label_no_format: true});
							// table
							var tb_dom = $(HandlebarsTemplates['sr_tb']({ 
								rows: data, 
								total: $.util.round(a[1].mean, 2), 
								average: true
							})).appendTo($('.table', q_con));
							_.each(categories, function(v, i){
								$('tr:eq(' + (i+1) + ') td:eq(0)', tb_dom).text(v);
							});
							$('tr:first th:last', tb_dom).text('回答人数');
							$('tr:last th:first', tb_dom).text('均值');
						} else if (q.question_type == 7) {
							// TimeBlank
							if(!a) a = [0, {mean: "", histogram: [], segment: []}];
							var categories = [], data = [];
							switch(q.issue.format) {
								case 0:
									for(var t = 0; t < a[1]["segment"].length; t ++) {
										var time = new Date();
										time.setTime(a[1]["segment"][t] * 1000);
										a[1]["segment"][t] = time.getFullYear();
									};
									break;
								case 1:
									for(var t = 0; t < a[1]["segment"].length; t ++) {
										var time = new Date();
										time.setTime(a[1]["segment"][t] * 1000);
										a[1]["segment"][t] = time.getFullYear() + '/' + (time.getMonth() + 1);
									};
									break;
								case 2:
									for(var t = 0; t < a[1]["segment"].length; t ++) {
										var time = new Date();
										time.setTime(a[1]["segment"][t] * 1000);
										a[1]["segment"][t] = time.getFullYear() + '/' + (time.getMonth() + 1) + '/' + time.getDate();
									};
									break;
								case 3:
									for(var t = 0; t < a[1]["segment"].length; t ++) {
										var time = new Date();
										time.setTime(a[1]["segment"][t] * 1000);
										var hour = String(time.getHours());
										if(hour.length == 1)
											hour = '0' + hour;
										var minute = String(time.getMinutes());
										if(minute.length == 1)
											minute = '0' + minute;
										a[1]["segment"][t] = time.getFullYear() + '/' + (time.getMonth() + 1) + '/' + time.getDate() + ' ' 
											+ hour + ':' + minute;
									};
									break;
								case 4:
									for(var t = 0; t < a[1]["segment"].length; t ++) {
										var time = new Date();
										time.setTime(a[1]["segment"][t] * 1000);
										a[1]["segment"][t] = (time.getMonth() + 1) + '/' + time.getDate();
									};
									break;
								case 5:
									for(var t = 0; t < a[1]["segment"].length; t ++) {
										var time = new Date();
										time.setTime(a[1]["segment"][t] * 1000);
										var hour = String(time.getHours());
										if(hour.length == 1)
											hour = '0' + hour;
										var minute = String(time.getMinutes());
										if(minute.length == 1)
											minute = '0' + minute;
										a[1]["segment"][t] = hour + ':' + minute;
									};
									break;
								case 6:
									for(var t = 0; t < a[1]["segment"].length; t ++) {
										var time = new Date();
										time.setTime(a[1]["segment"][t] * 1000);
										var hour = String(time.getHours());
										if(hour.length == 1)
											hour = '0' + hour;
										var minute = String(time.getMinutes());
										if(minute.length == 1)
											minute = '0' + minute;
										var second = String(time.getSeconds());
										if(second.length == 1)
											second = '0' + second;
										a[1]["segment"][t] = hour + ':' + minute + ':' + second;
									};
									break;
							}
							for(var i = 0; i < a[1]["histogram"].length; i ++) {
								data.push(a[1]["histogram"][i]);
								if(i == 0)
									categories.push(a[1]["segment"][i] + "之前（含）")
								else if(i == a[1]["segment"].length)
									categories.push(a[1]["segment"][i-1] + "之后")
								else
									categories.push(a[1]["segment"][i-1] + "至" + a[1]["segment"][i] + "（含）");
							};
							// chart
							renderArea(q._id + '_chart', categories, [{ name: "选择人数", data: data }]);
							// table
							var tb_dom = $(HandlebarsTemplates['sr_tb']({ rows: data, total: a[0] })).appendTo($('.table', q_con));
							_.each(categories, function(v, i){
								$('tr:eq(' + (i+1) + ') td:eq(0)', tb_dom).text(v);
							});
							$('tr:first th:first', tb_dom).text('时间段');
						} else if (q.question_type == 4) {
							// EmailBlank
							if(!a) a = [0, {}];
							var categories = [], data = [];
							for(var mail in a[1]) {
								categories.push(mail.replace(/_/g, "."));
								data.push(a[1][mail]);
							};
							// chart
							renderColumn(q._id + '_chart', categories, [{ name: "回答人数", data: data }], {color_by_point: true});
							// table
							var tb_dom = $(HandlebarsTemplates['sr_tb']({ rows: data, total: a[0] })).appendTo($('.table', q_con));
							_.each(categories, function(v, i){
								$('tr:eq(' + (i+1) + ') td:eq(0)', tb_dom).text(v);
							});
							$('tr:first th:first', tb_dom).text('邮件服务商');
							$('tr:first th:last', tb_dom).text('回答人数');
						} else if (q.question_type == 8) {
							// AddressBlank
							if(!a) a = [0, {}];
							var categories = [], locations = [];
							for(var address in a[1]) {
								categories.push(address);
								locations.push(a[1][address]);
							};
							// chart
							$('.q-content', q_con).addClass('wide');
							$('.chart', q_con).css({marginTop: 'auto'});
							var mc = [];
							var chart = $.od.odBmap({id_name: "chart-map", width: '805px'});
							chart.appendTo('#' + q._id + '_chart');
							chart.odBmap('init');
							for(var x = 0; x < locations.length; x ++) {
								var location = locations[x][1].split(" - ").join("");
								var lat = Number(locations[x][2]["lat"]);
								var lng = Number(locations[x][2]["lng"]);
								var count = String(locations[x][0]);
								chart.odBmap("setMarkerLL", location, "选择人数", count, lat, lng);
							};
							// table
							$('.table', q_con).remove();
						} else if (q.question_type == 11) {
							//ConstSum
							if(!a) a = [0, {}];
							var items = [];
							for(var m = 0; m < q.issue.items.length; m ++)
								items.push(q.issue.items[m]);
							if(q.issue.other_item.has_other_item) 
								items.push(q.issue.other_item);
							var categories = [], data = [];
							for (var i = 0; i < items.length; i++) {
								categories.push($.richtext.print(items[i].content));
								var a_count = 0;
								if(a[1][items[i].id] != undefined)
									a_count = a[1][items[i].id];
								data.push(Number(a_count.toFixed(1)));
							};
							// chart 
							renderPie(q._id + '_chart', categories, [{ name: '平均比重', data: _.zip(categories, data) }]);
							// table
							var tb_dom = $(HandlebarsTemplates['sr_tb']({ 
								rows: _.map(data, function(d) { return d + '%'; }), 
								total: a[0]
							})).appendTo($('.table', q_con));
							_.each(items, function(v, i){
								renderRichtext(q._id, $('tr:eq(' + (i+1) + ') td:eq(0)', tb_dom), v.content);
							});
							$('tr:first th:last', tb_dom).text('平均比重');
						} else if (q.question_type == 12) {
							// Sort
							if(!a) a = [0, {}];
							var items = [];
							for(var m = 0; m < q.issue.items.length; m ++)
								items.push(q.issue.items[m]);
							if(q.issue.other_item.has_other_item) 
								items.push(q.issue.other_item);
							var categories = [], series = [];
							var num = 1;
							for(var id in a[1]) {
								categories.push("第" + num + "位");
								series.push({ 
									name: $.richtext.print((_.find(items, function(v) { return (v.id == id); }) || {}).content) || '', 
									data: a[1][id] || [] 
								});
								num ++;
							};
							// chart
							$('.q-content', q_con).addClass('wide');
							$('.chart', q_con).css({height: 70 * categories.length + 'px'});
							renderBar(q._id + '_chart', categories, series, {stacking: true, legend_horizontal: true});
							// table
							var tb_dom = $(HandlebarsTemplates['sr_tb_wide']({ 
								column_count: items.length,
								row_count: items.length
							})).appendTo($('.table', q_con));
							$('<div class="tfoot" >（统计每个选项的各排名选择人数及平均排名位置）</div>').insertAfter(tb_dom);
							$('tr', tb_dom).each(function() { $('td:last,th:last', $(this)).addClass('tr'); });
							$('tr:last th', tb_dom).addClass('tb');
							$('tr:last th:first', tb_dom).text('排序均值');
							_.each(items, function(v, i) {
								renderRichtext(q._id, $('tr:eq(0) th:eq(' + (i + 1) +')', tb_dom), v.content);
							});
							_.each(categories, function(v, i) {
								$('tr:eq(' + (i + 1) + ') th:eq(0)', tb_dom).text(v);
							});
							_.each(series, function(s, i) {
								var total = 0;
								_.each(s.data, function(d, k) {
									$('tr:eq(' + (k + 1) + ') td:eq(' + i + ')', tb_dom).text(d);
									total += d * (k + 1);
								});
								$('tr:last th:eq(' + (i + 1) + ')', tb_dom).text($.util.round(total/categories.length, 2));
							});
						} else if (q.question_type == 17) {
							// scale
							if(!a) a = [0, {}];
							var categories = _.map(q.issue.items, function(v) { return $.richtext.print(v.content); });
							var series = [];
							_.each(q.issue.labels, function(label, i) {
								series.push({
									type: 'column',
									name: label + '（' + (i+1) + '分）',
									data: _.map(q.issue.items, function(item) { return a[1][item.id].histogram[i+1]; })
								});
							});
							if(q.issue.show_unknown)
								series.push({
									type: 'column',
									name: '不清楚',
									data: _.map(q.issue.items, function(item) { return a[1][item.id].histogram[0]; })
								});
							var spline_color = COLORS[(series.length < COLORS.length) ? series.length : (COLORS.length - 1)];
							series.push({
								type: 'spline',
								name: '均值',
								data: _.map(q.issue.items, function(item) { return $.util.round(a[1][item.id].mean, 2); }),
								yAxis: 1,
								lineColor: spline_color,
								marker: {
									lineWidth: 2,
									lineColor: spline_color,
									fillColor: '#fff'
								}
							});
							// chart
							$('.q-content', q_con).addClass('wide');
							var chart = new Highcharts.Chart(_.extend({}, CHART_DEFAULT_SETTING, {
								chart: { renderTo: q._id + '_chart' },
								legend: _getLegend(true),
								xAxis: {
									categories: categories,
									lineColor: GRID_LINE_COLOR,
									labels: { style: {color: X_LABEL_COLOR} },
								},
								yAxis: [{
									title: {
										text: '样本数量',
										style: { color: Y_LABEL_COLOR },
										labels: { color: Y_LABEL_COLOR }
									},
									gridLineColor: GRID_LINE_COLOR,
									labels: { style: { color: Y_LABEL_COLOR } }
								}, {
									title: {
										text: '平均得分',
										style: { color: spline_color },
										labels: { color: spline_color }
									},
									gridLineColor: GRID_LINE_COLOR,
									labels: { style: { color: spline_color } },
									opposite: true
								}],
								series: series,
								plotOptions: {
									series: {
										shadow: false,
										borderWidth: 0,
										showInLegend: true,
										// dataLabels: {enabled: true}
									}
								},
							}));
							// table
							var tb_dom = $(HandlebarsTemplates['sr_tb_scale']({ 
								column_count: q.issue.labels.length,
								row_count: q.issue.items.length,
								unknown: q.issue.show_unknown
							})).appendTo($('.table', q_con));
							$('<div class="tfoot" >（统计每个选项的各标签选择人数及平均分）</div>').insertAfter(tb_dom);
							$('tr:last', tb_dom).children().addClass('tb');
							_.each(q.issue.items, function(v, i) {
								renderRichtext(q._id, $('tr:eq(' + (i + 1) + ') th:eq(0)', tb_dom), v.content);
							});
							_.each(q.issue.labels, function(v, i) {
								$('tr:eq(0) th:eq(' + (i + 1) +')', tb_dom).text(v + '（' + (i+1) + '分）');
							});
							_.each(q.issue.items, function(item, i) {
								_.each(a[1][item.id].histogram, function(h, k) {
									$('tr:eq(' + (i+1) + ') td:eq(' + k +')', tb_dom).text(h);
								});
								$('tr:eq(' + (i+1) + ') th:last', tb_dom).text($.util.round(a[1][item.id].mean, 2));
							});
							if(q.issue.show_unknown)
								_.each(q.issue.items, function(item, i) {
									$('tr:eq(' + (i+1) + ') td:eq(' + (q.issue.labels.length + 1) +')', tb_dom).text(a[1][item.id].histogram[0]);
								});
						} else if (q.question_type == 2 || q.question_type == 5 || q.question_type == 6) {
							// TextBlank, UrlBlank
							$('.q-content', q_con).addClass('wide');
							$('.chart', q_con).remove();
							var tb_con = $('.table', q_con).css({marginBottom: 'auto'});
							if(q.question_type == 6) {
								tb_con.text('（为保护答题者隐私，电话题统计结果不展示）');
							} else {
								if(!a) a = [0, []];
								$(HandlebarsTemplates['sr_texts']({texts: a[1]})).appendTo(tb_con);
							}
						}
					}
				};

				// load next page
				if(page_index < window.survey_questions.pages.length) {
					loadAnswers(job_id, page_index + 1, question_index);
				}
			} else {
				// failed to load page
				var error_dom = $(HandlebarsTemplates['sr_waiting']({error: true}));
				page_dom.replaceWith(error_dom);
				$('a', error_dom).click(function() {
					error_dom.remove();
					loadAnswers(job_id, page_index, question_index);
				});
			}
		});
	};

	// export report
	var report_uri_cache = {};
	function exportReport(job_id, report_type) {
		function _finished(file_uri) {
			report_uri_cache[job_id + '_' + report_type] = file_uri;
			var url = '<%=Rails.application.config.dotnet_web_service_uri  %>' + file_uri;
			var info_con = $('<div >导出完成，浏览器将自动下载结果，您也可以 <a style="color: #6d91a9" target="_blank">点击此处</a> 手动下载。</div>');
			$('a', info_con).attr('href', url);
			$.od.odPopup({ title: '导出完成', content: info_con });
			window.open(url);
		};
		var file_uri = report_uri_cache[job_id + '_' + report_type];
		if(file_uri != null) {
			_finished(file_uri);
			return;
		}

		var pop_con = $('<div style="text-align:center; padding-top: 10px;"/>');
		var export_pb = $.od.odProgressbar({width: 160}).appendTo(pop_con);
		var waiting_pop = $.od.odPopup({ type:null, title: '正在导出 ...', content: pop_con, closeButton: false });
		function _failed() {
			if(waiting_pop) waiting_pop.odPopup('destroy');
			$.od.odPopup({ title: '导出失败', content: '导出失败，请重试。' });
		};
		// 1. get export job id
		$.getJSON('/questionaires/' + window.survey_id + '/result/report.json', {
			report_mockup_id: '',
			report_style: 0,
			report_type: report_type,
			analysis_task_id: job_id
		}, function(retval) {
			if(retval.success) {
				// 2. check export job progress
				function _getExportResult(job_id) {
					$.getJSON('/jobs/' + job_id + '.json', function(retval) {
						if(retval.success && retval.value >= 0) {
							export_pb.odProgressbar('option', 'value', retval.value);
							if(retval.value >= 1) {
								if(waiting_pop) waiting_pop.odPopup('destroy');
								// get url
								$.getJSON('/jobs/' + job_id + '/file_uri.json', function(retval) {
									if(retval.success) {
										_finished(retval.value);
									} else {
										_failed();
									}
								});
							} else {
								setTimeout(function() { _getExportResult(job_id); }, TIME_STEP);
							}
						} else {
							_failed();
						}
					});
				};
				_getExportResult(retval.value);
			} else {
				_failed();
			}
		});
	};

});