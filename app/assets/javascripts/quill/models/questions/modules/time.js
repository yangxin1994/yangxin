/* ================================
 * Module to manipulate time question issue
 * ================================ */

$(function(){

	function _mili_to_ary(milisec) {
		var date = new Date(milisec);
		return [date.getFullYear(), date.getMonth(), date.getDate(), 
			date.getHours(), date.getMinutes(), date.getSeconds(), date.getMilliseconds()];
	};
	function _ary_to_mili(ary) {
		return (new Date(ary[0], ary[1], ary[2], ary[3], ary[4], ary[5], ary[6])).getTime();
	};

	window.quill.modules.time = function(model, issue) {
		if(!model || !issue) return;

		// set issue init value
		$.extend(issue, $.extend({
			format: 2,	// 0 - 6, 年、年月、年月日、年月日时分、月日、时分、时分秒
			min: $.util.MIN_TIME,	// include
			max: $.util.MAX_TIME		// include
		}, issue));

		// adjust issue value
		if(!_.isNumber(issue.min))
			issue.min = $.util.MIN_TIME;
		if(!_.isNumber(issue.max))
			issue.max = $.util.MAX_TIME;
		if(issue.min == 0 && issue.max == 0) {
			issue.min = $.util.MIN_TIME;
			issue.max = $.util.MAX_TIME;
		};
		if(issue.format < 0 || issue.format > 6) 
			issue.format = 2;

		// extend handler
		var handler = {
			target: issue,
			setFormat: function(format) {
				if(format < 0 || format > 6) return;
				if(issue.format == format) return;
				issue.format = format;
				model.trigger('change:time:format', handler);
			},
			setMinMax: function(min, max) {
				if(min == issue.min && max == issue.max) return;

				if(min != $.util.MIN_TIME && max != $.util.MAX_TIME) {
					var min_ary = _mili_to_ary(min);
					var max_ary = _mili_to_ary(max);

					function _check(low_bound, up_bound) {
						var i = low_bound;
						for (; i < up_bound; i++) {
							if(max_ary[i] > min_ary[i])
								break;
							else
								max_ary[i] = min_ary[i];
						};
					}

					switch(issue.format) {
						case 0: _check(0, 1); break; // 年
						case 1: _check(0, 2); break; // 年月
						case 2: _check(0, 3); break; // 年月日
						case 3: _check(0, 5); break; // 年月日时分
						case 4: _check(1, 3); break; // 月日
						case 5: _check(3, 5); break; // 时分
						case 6: _check(3, 6); break; // 时分秒
					}
					max = _ary_to_mili(max_ary);
				}

				issue.min = min;
				issue.max = max;
				model.trigger('change:time:min_max', handler);
			},
			getMinMaxType: function() {
				if(issue.min == $.util.MIN_TIME) {
					return (issue.max == $.util.MAX_TIME) ? 0 : 1;
				} else {
					return (issue.max == $.util.MAX_TIME) ? 2 : 3;
				}
			},

			_getInfo: function() {
				return '请选择时间';
			},

			_checkAnswer: function(answer) {
				return isNaN(answer) ? '请选择时间' : null;
			}
		};

		return handler;

	};

});