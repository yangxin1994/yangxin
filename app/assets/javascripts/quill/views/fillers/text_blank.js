/* ================================
 * View: Text blank question render
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.fillers.TextBlank', quill.views.fillers.Base, {
		
		_render: function() {
			var con = this.$('.q-content');
			var ipt = this.model_issue.has_multiple_line ? $('<textarea />') : $('<input type="text" />');
			ipt.attr('id', this.model.id).appendTo(con);
			switch(this.model_issue.size) {
				case 0: ipt.addClass('normal'); break;
				case 1: ipt.addClass('middle'); break;
				case 2: ipt.addClass('wide'); break;
			}
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
