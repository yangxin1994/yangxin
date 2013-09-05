//=require ./_base
//=require ./_templates/od_checkbox
 
/* ================================
 * The checkbox widget
 * ================================ */

(function($) {
	
	/* odCheckbox widget
	 * =============== */
	$.odWidget('odCheckbox', {
		
		/* The default setting for plugin
		 * ================================ */
		options: {
			checked: false,
			text: null,
			onChange: function(checked) {}
		},
		
		/* Set up the widget
		 * ================================ */
		_createEl: function() {
			this.element = this.hbs(this.options);
			
			this._cb = this._find('em');
			
			this.element.hover($.proxy(function() {
				this._cb.addClass('hover');
			}, this), $.proxy(function() {
				this._cb.removeClass('hover');
			}, this)).click($.proxy(function() {
				this._cb.removeClass('hover');
				this.val(!this.options.checked);
			}, this));
		},
		_cb: null,
		
		/* get and set value
		 * ================================ */
		val: function(value) {
			if(value == null) {
				// get
				return this.options.checked;
			} else {
				// set
				if(this.options.checked != value) {
					this.options.checked = value;
					
					if(value)
						this._cb.addClass('checked');
					else
						this._cb.removeClass('checked');
						
					if(this.options.onChange)
						this.options.onChange(value);
				}
			}
		}
		
	}); //end of widget
	
})(jQuery);
