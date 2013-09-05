/* ================================
 * View: Phone blank question editor
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.fillers.PhoneBlank', quill.views.fillers.Base, {
		
		_render: function() {
			var hint = '';
			switch(this.model_issue.phone_type) {
				case 1: hint = '例如：010-8888-8888'; break;
				case 2: hint = '例如：186-8888-8888'; break;
				case 3: hint = '例如：010-8888-8888 或 186-8888-8888'; break;
			}
			$('<input type="text" />').attr({
				placeholder: hint
			}).placeholder().appendTo(this.$('.q-content'));
		},

		setAnswer: function(answer) {
			this.$('input:text').val(answer);
		},
		_getAnswer: function() {
			return $.trim(this.$('input:text').val());
		}
		
	});
	
});
