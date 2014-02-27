/* ================================
 * View: Paragraph question editor
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.fillers.Paragraph', quill.views.fillers.Base, {
		
		_render: function() { 
			this.$('.q-info').remove();
			this.$('.q-required').remove();
			this.$('.q-error').remove();
			this.$('.q-idx').remove();
		},

		_setAnswer: function(answer) { },
		_getAnswer: function() { return {}; }
		
	});
	
});
