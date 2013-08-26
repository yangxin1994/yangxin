/* ================================
 * Enter on input:text
 * ================================ */

(function( $ ) {
	$.widget("oopsdata.odEnter", {
 
		// These options will be used as defaults
		options: { 
			enter: null
		},

		_event: null,
 
		// Set up the widget
		_create: function() {
			if(!this.element.is('input:text, input:password'))
				throw 'odEnter can only apply on input:text or input:password';
			this._bind(this.options.enter);
		},

		_bind: function(enter) {
			if(!enter) return;
			this._event = function(e) { if(e.which == 13) enter(e); };
			this.element.on('keydown', this._event);
		},
		_unbind: function() {
			this.element.off('keydown', this._event);
		},

		// Use the _setOption method to respond to changes to options
		_setOption: function( key, value ) {
			switch( key ) {
				case "enter":
					this._unbind();
					this._bind(value);
					break;
			}
			$.Widget.prototype._setOption.apply( this, arguments );
		},

		// Use the destroy method to clean up any modifications your widget has made to the DOM
		destroy: function() {
			this._unbind();
			$.Widget.prototype.destroy.call(this);
		}
	});
}(jQuery));