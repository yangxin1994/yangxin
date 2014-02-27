/* ================================
 * View: Url blank question editor
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.fillers.UrlBlank', quill.views.fillers.Base, {
		
		_render: function() {
			$('<input type="text" class="wide" placeholder="例如：www.baidu.com" />').placeholder().appendTo(this.$('.q-content'));
		},

		_setAnswer: function(answer) {
			this.$('input:text').val(answer);
		},
		_getAnswer: function() {
			return $.trim(this.$('input:text').val());
		}
		
	});
	
});
