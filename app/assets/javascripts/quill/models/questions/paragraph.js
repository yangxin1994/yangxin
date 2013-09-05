/* ================================
 * Model: Paragraph
 * ================================ */

$(function(){

	quill.quillClass('quill.models.questions.Paragraph', quill.models.questions.Base, {

		/* Default properties
		 * =========================== */
		_defaults: {
			issue: {}
		},

		_initialize: function() {
			this.set('is_required', false);
		},

		_checkAnswer: function(answer) {
			return null;
		}

	});

});