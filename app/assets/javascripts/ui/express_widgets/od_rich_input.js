//=require ./_base
//=require ./_templates/od_rich_input
 
(function($) {

	/* Adjust content of a value. 
	 * ================================ */
	function _adjust_value(value) {
		if(!value) value = {};
		if(!_.isString(value.text)) value.text = '';
		if(!_.isArray(value.image)) value.image = [];
		if(!_.isArray(value.video)) value.video = [];
		if(!_.isArray(value.audio)) value.audio = [];
		return value;
	};
	
	$.odWidget('odRichInput', {
		
		/* The default setting for plugin
		 * ================================ */
		options: {
			width: null,
			height: null,
			multiline: false,
			value: {
				text: 'text',
				image: [],
				audio: [],
				video: []
			}
		},
		
		/* Set up the widget
		 * ================================ */
		_createEl: function() {
			this.element = this.hbs(this.options);
			
			// setup inner input
			this._inner_input = this._find('input, textarea');
			if(this.options.width) {
				if(this.options.multiline)
					this._inner_input.css({width: (this.options.width - 5 - 5 - 2) + 'px'});
				else
					this._inner_input.css({width: (this.options.width - 5 - 5 - 2) + 'px'});
			}
			if(this.options.height)
				this._inner_input.css({height: (this.options.height - 2) + 'px'});
			this._inner_input.focus($.proxy(function() {
				this.active();
			}, this)).blur($.proxy(function() {
				this.unactive();
			}, this)).keyup($.proxy(function(){
				this.options.value.text = this._inner_input.val();
			}, this));

			// init value
			this.val(this.options.value);
		},
		_inner_input: null,

		/* Set option value
		 * ================================ */
		_setOption: function(key, value) {
			switch(key) {
				case "value":
					value = _adjust_value(value);
					this.refresh(value);
					break;
			}
			$.Widget.prototype._setOption.apply(this, arguments);
		},
		
		/* get and set value
		 * ================================ */
		val: function(value) {
			return (value == null) ? this.option('value') : this.option('value', value);
		},
		
		/* get the inner input to attach event handlers
		 * ================================ */
		innerInput: function() {
			return this._inner_input;
		},
		
		/* Active and unactive the rich input
		 * ================================ */
		_locked: false,
		active: function() {
			if(this._locked) return;
			this.element.addClass('active');
			this._find('.od-rich-input-btns').show();
		},
		unactive: function() {
			if(this._locked) return;
			this.element.removeClass('active');
		},
		refresh: function(value) {
			// set text
			this._inner_input.val(value.text);
		}
		
	});
	
})(jQuery);
