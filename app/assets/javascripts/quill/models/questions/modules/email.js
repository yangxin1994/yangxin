/* ================================
 * Module to manipulate email question issue
 * ================================ */

$(function(){

	window.quill.modules.email = function(model, issue) {
		if(!model || !issue) return;

		var handler = {
			target: issue,

			_getInfo: function(lang) {
				return lang == 'en' ? 'Email' : '请输入有效邮箱';
			},

			_checkAnswer: function(answer, lang) {
        if(!this.get('is_required')) {
          if(!answer)
            return null;
        }
				return $.regex.isEmail(answer) ? null : (lang=='en' ? 'Email is invalid' : '请输入有效邮箱');
			}
		};

		return handler;
	};

});