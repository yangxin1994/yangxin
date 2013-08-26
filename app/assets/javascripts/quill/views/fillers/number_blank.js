/* ================================
 * View: Number blank question render
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.fillers.NumberBlank', quill.views.fillers.Base, {
		
		_render: function() {
			var con = this.$('.q-content');
			var ipt = $('<input type="text" class="short" />').attr('id', this.model.id);
			var unit = $('<span />').text(this.model_issue.unit);
			switch(this.model_issue.unit_location) {
				case 0: ipt.appendTo(con); break;
				case 1: 
					ipt.appendTo(con);
					unit.appendTo(con).css({marginLeft: '10px'});
					break;
				case 2: 
					unit.appendTo(con).css({marginRight: '10px'});
					ipt.appendTo(con);
					break;
			}
		},

		setAnswer: function(answer) {
			if(!answer) return;
			this.$('#' + this.model.id).val(answer);
		},
		_getAnswer: function() {
			return parseFloat($.trim(this.$('#' + this.model.id).val()));
		}
		
	});
	
});
