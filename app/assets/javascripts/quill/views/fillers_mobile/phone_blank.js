/* ================================
 * View: Phone blank question editor
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.fillersMobile.PhoneBlank', quill.views.fillersMobile.Base, {
		
		_render: function() {
			var $p = $('<p />').appendTo(this.$('.q-content'));
			var hint = '';
			switch(this.model_issue.phone_type) {
				case 1: hint = '例如：010-8888-8888'; break;
				case 2: hint = '例如：186-8888-8888'; break;
				case 3: hint = '010-8888-8888 或 186-8888-8888'; break;
			}
			$('<input type="text" />').attr({
				placeholder: hint,
				name: "number",
				class: "txt-uniline"

			}).placeholder().appendTo($p);
		},

		setAnswer: function(answer) {
			this.$('input:text').val(answer);
		},
		_getAnswer: function() {
			return $.trim(this.$('input:text').val());
		}
		
	});
	
});
