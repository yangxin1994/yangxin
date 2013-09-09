//=require ./_base
//=require ./_templates/od_white_button
 
/* ================================
 * The WhiteButton widget
 * ================================ */

(function($) {
	
	$.odWidget('odWhiteButton', {
		
		/* The default setting for plugin
		 * ================================ */
		options: {
			text: null,
			icon: null, //'edit',
			info: null
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

			if(!this.options.text) {
				this._find('.icon').css('marginLeft', '0px');
				this._find('.op-white-btn-c span').remove();
			}

			// tooltip
			// if(this.options.info) {
			// 	this.element.tooltip({
			// 		placement: 'bottom'
			// 	});
			// }
		},
		$icon: null,

		_destroy: function() { 
			// this.element.tooltip('destroy');
		}
		
	});
	
})(jQuery);
