/* ================================
 * View: Email blank question render
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.fillers.EmailBlank', quill.views.fillers.Base, {
		
		_render: function() {
			$('<input type="text" placeholder="例如：myemail@sina.com" />').placeholder().appendTo(this.$('.q-content'));
		},

		_setAnswer: function(answer) {
			this.$('input:text').val(answer);
		},
		_getAnswer: function() {
			return $.trim(this.$('input:text').val());
		}
		
	});
	
});
