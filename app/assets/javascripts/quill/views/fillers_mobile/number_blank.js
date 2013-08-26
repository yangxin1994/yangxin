/* ================================
 * View: Number blank question render
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.fillersMobile.NumberBlank', quill.views.fillersMobile.Base, {
		
		_render: function() {
			var $p = $('<p />').appendTo(this.$('.q-content'));
			var ipt = $('<input type="text" />').attr('id', this.model.id).appendTo($p);
			var unit = $('<span />').text(this.model_issue.unit);
			switch(this.model_issue.unit_location) {
				case 0: 
					break;
				case 1: 
					unit.insertAfter(ipt).css({marginLeft: '5px'});
					break;
				case 2: 
					unit.insertBefore(ipt).css({marginRight: '5px'});
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
