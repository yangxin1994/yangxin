//=require ./_base
//=require ./od_rich_input
//=require ./_templates/od_item
 
/* ================================
 * The Item widget for editor
 * ================================ */

(function($) {
	
	$.odWidget('odItem', {
		
		/* The default setting for plugin
		 * ================================ */
		options: {
			id: null,
			width: null,
			value: {
				text: 'item',
				image: [],
				audio: [],
				video: []
			},
			hideDrag: false,
			hideRemove: false
		},
		
		/* Set up the widget
		 * ================================ */
		_createEl: function() {
			this.element = this.hbs(this.options);
			this._$richInput = $.od.odRichInput({
				width: this.options.width ? this.options.width - 21 - 26 + 3 : null,
				value: this.options.value
			}).appendTo(this._find('>div'));
			this._$removeBtn = this._find('.close-btn');
		},
		
		_$richInput: null,
		richInput: function() {
			return this._$richInput;
		},

		highlight: function(on) {
			on ? this._$richInput.odRichInput('innerInput').addClass('highlight') :
				this._$richInput.odRichInput('innerInput').removeClass('highlight');
		},
		
		other: function(on) {
			on ? this._$richInput.odRichInput('innerInput').addClass('other') :
				this._$richInput.odRichInput('innerInput').removeClass('other');
		},

		_$removeBtn: null,
		getRemoveBtn: function() {
			return this._$removeBtn;
		},
		
		_destroy: function() {
			this._$richInput = null;
			this._$removeBtn = null;
		}
		
	});
	
})(jQuery);
