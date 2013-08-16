//=require ./_base
//=require ./_templates/od_left_icon_button
 
/* ================================
 * The LeftIconButton widget
 * ================================ */

(function($) {
	
	$.odWidget('odLeftIconButton', {
		
		/* The default setting for plugin
		 * ================================ */
		options: {
			icon: 'add',
			text: null,
			width: null
		},
		
		/* Set up the widget
		 * ================================ */
		_createEl: function() {
			this.element = this.hbs(this.options);
			this.$icon = this._find('.icon');
			
			if(this.$icon.length > 0) {
				this.element.hover($.proxy(function() {
					this.$icon.addClass(this.options.icon + '-active');
				}, this), $.proxy(function() {
					this.$icon.removeClass(this.options.icon + '-active');
				}, this));
			}
		},
		$icon: null
		
	});
	
})(jQuery);
