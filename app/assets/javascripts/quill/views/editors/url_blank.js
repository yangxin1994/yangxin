//=require ../../templates/editors/url_blank_body

/* ================================
 * View: Url blank question editor
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.editors.UrlBlank', quill.views.editors.Base, {
		
		_initialize: function() {
		},

		_render: function() {
			
			this.$('.editor-method').hide();	// hide toggle between code and visual

			/* ================================
			 * Editor Left Part
			 * ================================ */
			
			// input preview
			this.hbs(null, 'url_blank_body').appendTo(this.$('.q-body'));

			/* ================================
			 * Editor Right Part
			 * ================================ */
			
		}
		
	});
	
});