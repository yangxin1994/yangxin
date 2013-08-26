//=require ./_base
//=require ./_templates/od_dropdown
 
/* ================================
 * The Dropdown widget
 * ================================ */

(function($) {
	
	$.odWidget('odDropdown', {
		
		/* The default setting for plugin
		 * ================================ */
		options: {
			values: [],
			width: 100,
			onSetIndex: function(index) {}
		},
		
		/* Set up the widget
		 * ================================ */
		_createEl: function() {
			this.element = this.hbs({
				values: this.options.values,
				width: this.options.width
			}).hide();
			
			this._find('>li:first-child').addClass('first-child');
			this._find('>li:last-child').addClass('last-child');
			this._find('>li:odd').addClass('odd');
			
			// update index and hide when mousedown
			this.element.mousedown($.proxy(function(e) {
				if(this.options.onSetIndex)
					this.options.onSetIndex($(e.target).index());
				this.hide();
				e.stopPropagation();
			}, this));
		},
		
		/* Attach the dropdown to a target
		 * ================================ */
		_target: null,
		_offset_down: 0,
		_offset_right: 0,
		attachTo: function($target, moveDown, moveRight) {
			this._target = $target;
			this._target.addClass('od-dropdown-target');
			this._target.append(this.element);
			if(moveDown)
				this._offset_down = moveDown;
			if(moveRight)
				this._offset_right = moveRight;
		},
		
		/* Show and hide dropdown
		 * ================================ */
		show: function() {
			this.element.css({
				top: this._target.height() + this._offset_down + 'px',
				left: this._offset_right + 'px'
			});
			
			this.element.slideDown('fast');
					
			$(document).one('mousedown', $.proxy(function() {
				this.hide();
			}, this));
		},
		hide: function() {
			this.element.slideUp('fast');
		},
		
		/* Destroy the widget. Remove target's class
		 * ================================ */
		_destroy: function() {
			if(this._target) {
				this._target.removeClass('od-dropdown-target');
			}
		}
		
	});
	
})(jQuery);
