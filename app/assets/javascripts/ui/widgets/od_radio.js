//=require ./_base
//=require ./_templates/od_radio
 
/* ================================
 * The Radio widget
 * ================================ */

(function($) {
	
	var _radio_groups = {};
	
	$.odWidget('odRadio', {
		
		/* The default setting for plugin
		 * ================================ */
		options: {
			checked: false,
			text: null,
			onChange: function(checked) {},
			group: null,
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
				this.val(true);
			}, this));
			
			// add to group
			if(this.options.group) {
				var group = (_radio_groups[this.options.group] = _radio_groups[this.options.group] || []);
				if($.inArray(this, group) == -1)
					group.push(this);
			}
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
					if(value) {
						this._cb.addClass('checked');
						if(this.options.group) {
							var group = _radio_groups[this.options.group];
							for(var i=0; i<group.length; i++) {
								if(group[i] != this)
									group[i].val(false);
							}
						}
					} else {
						this._cb.removeClass('checked');
					}
						
					if(this.options.onChange)
						this.options.onChange(value);
				}
			}
		}
		
	});
	
})(jQuery);
