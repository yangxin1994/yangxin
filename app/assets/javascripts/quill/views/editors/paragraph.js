//=require ../../templates/editors/paragraph

/* ================================
 * Paragraph editor
 * ================================ */

$(function(){

	/* Paragraph editor
	 * =========================== */
	quill.quillClass('quill.views.editors.Paragraph', quill.views.Base, {
		
		_initialize: function() {
			this.model.on('change:content', this.refreshContent, this);
		},

		_render: function() {
			this.replaceElement(this.hbs(this.model.toJSON(), 'paragraph'));
			
			// content
			$.od.odRichInput({
				id: this._domId('content_ipt'),
				width: 575,
				height: 100,
				multiline: true
			}).appendTo(this.$('.p-content'));
			this._findDom('content_ipt').odRichInput('innerInput').css('background', 'none').blur($.proxy(function() {
				this.model.set('content', this._findDom('content_ipt').odRichInput('val'));
			}, this));
			this.refreshContent();
			
			// btn
			var $cancel_btn = this.$('.cancel-btn').click(this.options.cancel);
			var $confirm_btn = this.$('.ok-btn').click($.proxy(function() {
				//TODO
				// this._$confirm_btn.attr('disabled', true);
				this.model.save({
					error: $.proxy(function() {
						//TODO
					}, this),
					success: this.options.confirm
				});
			}, this));

		},

		refreshContent: function() {
			this._findDom('content_ipt').odRichInput('val', this.model.get('content'));
		},

		/* Refresh index display
		 * =========================== */
		refreshIndex: function(index) { }
		
	});

});