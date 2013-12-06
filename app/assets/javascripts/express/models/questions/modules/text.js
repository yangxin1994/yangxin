/* ================================
 * Module to manipulate text question issue
 * ================================ */

$(function(){

	window.quill.modules.text = function(model, issue) {
		if(!model || !issue) return;

		// set issue init value
		$.extend(issue, $.extend({
			min_length: 0,		// -1 means not defined
			max_length: 100,
			has_multiple_line: false,
			size: 1 	// 0, 1, 2
		}, issue));

		// extend handler
		var handler = {
			target: issue,
			getMinMaxType: function() {
				if(issue.min_length < 0) {
					return (issue.max_length < 0) ? 0 : 2;
				} else {
					return (issue.max_length < 0) ? 1 : 3;
				}
			},
			setMinMax: function(min, max) {
				if(isNaN(min)) min = 0;
				if(isNaN(max)) max = 100;
				if(issue.min_length == min && issue.max_length == max) return;
				if(max > 0 && min > max) min = max;
				issue.min_length = min;
				issue.max_length = max;
				model.trigger('change:text:min_max', handler);
			},

			setMultiple: function(multiple) {
				if(issue.has_multiple_line == multiple) return;
				issue.has_multiple_line = multiple;
				model.trigger('change:text:multiple', handler);
			},

			setSize: function(size) {
				if(issue.size == size) return;
				issue.size = size;
				model.trigger('change:text:size', handler);
			},

			_getInfo: function() {
				if(issue.min_length <= 0) {
					return (issue.max_length <= 0) ? null : ('不超过 ' + issue.max_length + ' 个字');
				} else {
					return (issue.max_length <= 0) ? ('不少于 ' + issue.min_length + ' 个字') : 
						('输入 ' + issue.min_length + ' 到 ' + issue.max_length + ' 个字');
				}
			},

			_checkAnswer: function(answer) {
				if(answer.length == 0) return '请输入内容';
				if(issue.min_length >= 0 && answer.length < issue.min_length) return '至少输入 ' + issue.min_length + ' 个字';
				if(issue.max_length >= 0 && answer.length > issue.max_length) return '最多输入 ' + issue.max_length + ' 个字';
				return null;
			}
			
		};

		return handler;
	};

});