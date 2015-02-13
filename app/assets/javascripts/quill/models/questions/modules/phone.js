/* ================================
 * Module to manipulate phone question issue
 * ================================ */

$(function(){

	window.quill.modules.phone = function(model, issue) {
		if(!model || !issue) return;

		// set issue init value
		$.extend(issue, $.extend({
			phone_type: 1 	// 1 << 0 phone, 1 << 1 mobile, 1 << 1 + 1 << 0 phone and mobile
		}, issue));

		// extend handler
		var handler = {
			target: issue,
			/* Friendly format: 
			 * 0 phone, 1 mobile, 2 phone and mobile
			 * ============================ */
			getPhoneType: function() {
				return issue.phone_type - 1;
			},
			setPhoneType: function(val) {
				var type = val + 1;
				if(issue.phone_type == type) return;
				issue.phone_type = type;
				model.trigger('change:phone:phone_type', handler);
			},

			_getInfo: function(lang) {
				switch(issue.phone_type) {
					case 1: return lang=='en' ? 'Telephone number' : '请输入座机号';
					case 2: return lang=='en' ? 'Mobile phone number' : '请输入手机号';
					default: return lang=='en' ? 'Telephone or mobile number' : '请输入电话号码';
				}
			},

			_checkAnswer: function(answer, lang) {
				switch(issue.phone_type) {
					case 1: return $.regex.isPhone(answer) ? null : (lang=='en' ? 'Please input a correct telephone number.' : '请输入正确的座机号');
					case 2: return $.regex.isMobile(answer) ? null : (lang=='en' ? 'Please input a correct mobile phone number.' : '请输入正确的手机号码');
					case 3: return ($.regex.isPhone(answer) || $.regex.isMobile(answer)) ? null : (lang=='en' ? 'Please input a correct phone number.' : '请输入正确的电话号码');
				}
				return null;
			}
			
		};

		return handler;
	};

});