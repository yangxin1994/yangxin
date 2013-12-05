//=require ../../templates/editors/email_blank_body

/* ================================
 * View: Url blank question editor
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.editors.EmailBlank', quill.views.editors.Base, {
		
		_initialize: function() {
		},

		_render: function() {
			
			this.$('.editor-method').hide();	// hide toggle between code and visual

			/* ================================
			 * Editor Left Part
			 * ================================ */
			
			// input preview
			this.hbs(null, 'email_blank_body').appendTo(this.$('.q-body'));

			/* ================================
			 * Editor Right Part
			 * ================================ */
			
		}
		
	});
	
});