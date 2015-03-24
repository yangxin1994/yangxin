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

			_getInfo: function(lang) {
        if(lang=='en') {
          if(issue.min_length <= 0) {
            return (issue.max_length <= 0) ? null : ('No more than ' + issue.max_length + ' words');
          } else {
            if(issue.max_length <= 0) {
              return 'At least ' + issue.min_length + ' words';
            } else {
              if(issue.max_length == issue.min_length) {
                return issue.min_length + ' words';
              } else {
                return issue.min_length + ' to ' + issue.max_length + ' words';
              }
            }
          }
        } else {
          if(issue.min_length <= 0) {
            return (issue.max_length <= 0) ? null : ('不超过 ' + issue.max_length + ' 个字');
          } else {
            if(issue.max_length <= 0) {
              return '不少于 ' + issue.min_length + ' 个字';
            } else {
              if(issue.max_length == issue.min_length) {
                if(issue.max_length == 18) {
                  return '输入有效身份证号';
                } else {
                  return '输入 ' + issue.min_length + ' 个字';
                }
              } else {
                return '输入 ' + issue.min_length + ' 到 ' + issue.max_length + ' 个字';
              }
            }
          }
        }
			},

			_checkAnswer: function(answer, lang) {
        if(!this.get('is_required')) {
          if(!answer || answer.length == 0)
            return null;
        }
        if(lang=='en') {
          if(answer.length == 0) return 'Please input text';
          if(issue.min_length >= 0 && answer.length < issue.min_length) return 'Input at least ' + issue.min_length + ' words';
          if(issue.max_length >= 0 && answer.length > issue.max_length) return 'Input no more than ' + issue.max_length + ' words';
          return null;
        } else {
          if(answer.length == 0) return '请输入内容';
          if(issue.max_length == issue.min_length && issue.max_length == 18) {
            // id card
            if(!$.idcard.isValid(answer)) {
              return '请输入有效身份证号';
            } else {
              return null;
            }
          }
          if(issue.min_length >= 0 && answer.length < issue.min_length) return '至少输入 ' + issue.min_length + ' 个字';
          if(issue.max_length >= 0 && answer.length > issue.max_length) return '最多输入 ' + issue.max_length + ' 个字';
          return null;
        }
			}
			
		};

		return handler;
	};

});