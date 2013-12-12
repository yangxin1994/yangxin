//=require ui/express_widgets/od_time_selector

/* ================================
 * View: Time blank question editor
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.fillersMobile.TimeBlank', quill.views.fillersMobile.Base, {

		_time_selector: null,
		
		_render: function() {
			this._time_selector = $.od.odTimeSelector({
				format: this.model_issue.format,
				min: this.model_issue.min,
				max: this.model_issue.max
			}).appendTo(this.$('.q-content'));
		},

		setAnswer: function(answer) {
			if(!answer) return;
			this._time_selector.odTimeSelector('val', answer);
		},
		_getAnswer: function() {
			return this._time_selector.odTimeSelector('checkInput') ? this._time_selector.odTimeSelector('val') : NaN;
		}
		
	});
	
});
