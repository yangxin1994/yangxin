/* ================================
 * View: Url blank question editor
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.fillersMobile.UrlBlank', quill.views.fillersMobile.Base, {
		
		_render: function() {
			var $p = $('<p />').appendTo(this.$('.q-content'));
			$('<input type="text" class="txt-uniline" placeholder="例如：www.oopsdata.com" />').placeholder().appendTo($p);
		},

		setAnswer: function(answer) {
			this.$('input:text').val(answer);
		},
		_getAnswer: function() {
			return $.trim(this.$('input:text').val());
		}
		
	});
	
});
