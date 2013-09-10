/* ================================
 * Module to manipulate email question issue
 * ================================ */

$(function(){

	window.quill.modules.url = function(model, issue) {
		if(!model || !issue) return;

		var handler = {
			target: issue,

			_getInfo: function() {
				return '请输入网页地址';
			},

			_checkAnswer: function(answer) {
				return $.regex.isUrl(answer) ? null : '请输入有效的链接地址';
			}
		};

		return handler;
	};

});