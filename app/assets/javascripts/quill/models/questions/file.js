/* ================================
 * Model: File Upload Question
 * ================================ */

$(function(){
	
	quill.quillClass('quill.models.questions.File', quill.models.questions.Base, {

		/* Default properties
		 * =========================== */
		_defaults: {
			issue: {
			}
		},
		
		_initialize: function() {
		},
		
		validate: function(attrs) { },

	});

});