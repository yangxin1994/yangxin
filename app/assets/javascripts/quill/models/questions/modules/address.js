/* ================================
 * Module to manipulate address question issue
 * ================================ */

$(function(){

	window.quill.modules.address = function(model, issue) {
		if(!model || !issue) return;

		// set issue init value
		$.extend(issue, $.extend({
			has_postcode: true,
			format: 15
		}, issue));

		// handler
		var handler = {
			target: issue,

			setPostcode: function(has_postcode) {
				if(issue.has_postcode == has_postcode) return;
				issue.has_postcode = has_postcode;
				model.trigger('change:address:has_postcode', handler);
			},

			/* Friendly format: 
			 * 0 province, 1 city, 2 town, 3 detail
			 * ============================ */
			getFormat: function() {
				for (var i = 0; i < 4; i++) {
					if((issue.format & (1 << i)) > 0)
						return (3 - i);
				};
				return 0;
			},
			setFormat: function(val) {
				var format = 15;
				switch(val) {
					case 0: format = 8; break;
					case 1: format = 12; break;
					case 2: format = 14; break;
					case 3: format = 15; break;
				}
				if(issue.format == format) return;
				issue.format = format;
				model.trigger('change:address:format', handler);
			},

			_getInfo: function() {
				if(issue.format == 15) {
					return issue.has_postcode ? '请填写详细地址和邮编' : '请填写详细地址';
				} else {
					return issue.has_postcode ? '请选择地址并输入邮编' : '请选择地址';
				}
			},

			_checkAnswer: function(answer) {
				if(answer.address == undefined || answer.address < 0) return '请选择地址';
				if(handler.getFormat() == 3 && !answer.detail) return '请输入详细地址';
				if(issue.has_postcode && !$.regex.isPostcode(answer.postcode)) return '请输入正确邮编';
				return null;
			}
			
		};

		return handler;
	};

});