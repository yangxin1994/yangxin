//=require ./_base
//=require ./od_dropdown
//=require ./_templates/od_selector
 
/* ================================
 * The selector widget
 * ================================ */

(function($) {
	
	$.odWidget('odSelector', {
		
		/* The default setting for plugin
		 * ================================ */
		options: {
			values: [],
			index: 0,
			width: 180,
			onChange: function(index) {}
		},

		/* Set up the widget
		 * ================================ */
		_createEl: function() {
			this.element = this.hbs({
				text: this.options.values[this.options.index],
				width: this.options.width
			});
			
			this._dropdown = $.od.odDropdown({
				values : this.options.values,
				width: this.options.width - 26,
				onSetIndex: $.proxy(function(index) {
					this.index(index);
				}, this)
			});
			this._find('span').css('width', this.options.width - 26 + 'px');
			
			this._dropdown.odDropdown('attachTo', this.element, -1);
			
			this.element.mousedown($.proxy(function(e) {
				this._dropdown.odDropdown('show');
				e.stopPropagation();
			}, this));
		},
		
		_dropdown: null,
		
		/* get and set index
		 * ================================ */
		index: function(index) {
			if(index == null) {
				// get
				return this.options.index;
			} else {
				// set
				if(index < 0 || index > this.options.values.length)
					return;
					
				var trigger = this.options.index != index;
				this.options.index = index;
				this._find('span').text(this.options.values[this.options.index]);
				
				if(trigger && this.options.onChange)
					this.options.onChange(index);
			}
		},
		
		/* Destroy the dropdown
		 * ================================ */
		_destroy: function() {
			this._dropdown.odDropdown('destroy');
		}
	});
	
})(jQuery);
