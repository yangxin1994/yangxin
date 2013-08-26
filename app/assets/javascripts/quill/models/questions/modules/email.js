/* ================================
 * Module to manipulate email question issue
 * ================================ */

$(function(){

	window.quill.modules.email = function(model, issue) {
		if(!model || !issue) return;

		var handler = {
			target: issue,

			_getInfo: function() {
				return '请输入有效邮箱';
			},

			_checkAnswer: function(answer) {
				return $.regex.isEmail(answer) ? null : '请输入有效邮箱';
			}
		};

		return handler;
	};

});