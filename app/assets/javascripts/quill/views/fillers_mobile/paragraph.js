/* ================================
 * View: Paragraph question editor
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.fillersMobile.Paragraph', quill.views.fillersMobile.Base, {
		
		_render: function() { 
			this.$('.q-info').remove();
			this.$('.q-required').remove();
			this.$('.q-error').remove();
			this.$('.q-idx').remove();
		},

		setAnswer: function(answer) { },
		_getAnswer: function() { return {}; },
		
	});
	
});
