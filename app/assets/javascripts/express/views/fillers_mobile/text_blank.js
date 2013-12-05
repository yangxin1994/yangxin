/* ================================
 * View: Text blank question render
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.fillersMobile.TextBlank', quill.views.fillersMobile.Base, {
		
		_render: function() {
			var $p = $('<p />').appendTo(this.$('.q-content'));
			var ipt = this.model_issue.has_multiple_line ? $('<textarea class="txt-Multiline" />') : $('<input type="text" class="txt-uniline" />');
			ipt.attr('id', this.model.id).appendTo($p);
		},

		setAnswer: function(answer) {
			if(!answer) return;
			this.$('#' + this.model.id).val(answer);
		},
		_getAnswer: function() {
			return this.$('#' + this.model.id).val();
		}
		
	});
	
});
