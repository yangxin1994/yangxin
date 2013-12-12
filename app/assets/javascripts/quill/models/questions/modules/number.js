/* ================================
 * Module to manipulate number question issue
 * ================================ */

$(function(){

	window.quill.modules.number = function(model, issue) {
		if(!model || !issue) return;

		// set issue init value
		$.extend(issue, $.extend({
			precision: 0,
			min_value: 0,
			max_value: 100,
			unit: '',
			unit_location: 0	//可以是0, 1（单位在后）或者2（单位在前）
		}, issue));

		var MAX_INT = Math.pow(2, 30), MIN_INT = - Math.pow(2, 30);

		// extend handler
		var handler = {
			MAX_INT: MAX_INT,
			MIN_INT: MIN_INT,
			
			target: issue,

			setPrecision: function(val) {
				if(issue.precision == val) return;
				issue.precision = val;
				model.trigger('change:number:precision', handler);
			},

			getMinMaxType: function() {
				if(issue.min_value == MIN_INT) {
					return (issue.max_value == MAX_INT) ? 0 : 2;
				} else {
					return (issue.max_value == MAX_INT) ? 1: 3;
				}
			},
			setMinMax: function(min, max) {
				if(isNaN(min)) min = MIN_INT;
				if(isNaN(max)) max = MAX_INT;
				if(issue.min_value == min && issue.max_value == max) return;
				if(min > max)	min = max;
				issue.min_value = min;
				issue.max_value = max;
				model.trigger('change:number:min_max', handler);
			},

			setUnit: function(unit) {
				if(issue.unit == unit) return;
				issue.unit = unit;
				model.trigger('change:number:unit', handler);
			},

			setUnitLocation: function(location) {
				if(issue.unit_location == location) return;
				issue.unit_location = location;
				model.trigger('change:number:unit_location', handler);
			},

			_getInfo: function() {
				var type = (issue.precision == 0) ? '整数' : '小数';
				var retval = null;
				if(issue.min_value == model.MIN_INT) {
					if(issue.max_value == model.MAX_INT) retval = '请输入' + type;
					else retval = '请输入小于或等于 ' + issue.max_value + ' 的' + type;
				} else {
					if(issue.max_value == model.MAX_INT) retval = '请输入大于或等于 ' + issue.min_value + ' 的' + type;
					else retval = '请输入 ' + issue.min_value + ' 到 ' + issue.max_value + ' 之间的' + type;
				}
				if(issue.precision > 0) {
					retval = retval + '，精确到小数点后' + issue.precision + '位';
				}
				return retval;
			},

			_checkAnswer: function(answer) {
				if(isNaN(answer)) return '请输入数值';
				if(answer < issue.min_value) return '输入不能小于 ' + issue.min_value;
				if(answer > issue.max_value) return '输入不能大于 ' + issue.max_value;
				if(issue.precision == 0) {
					if((answer + '').indexOf('.') >= 0)
						return '请输入整数';
				} else if(issue.precision > 0) {
					var splits = ((answer + '').split('.'));
					if(splits.length == 2 && splits[1].length > issue.precision)  
						return '请精确到小数点后' + issue.precision + '位数字';
				}
				return null;
			}
			
		};

		return handler;
	};

});