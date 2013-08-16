/* ================================
 * Set the value of input or href of a from url param
 * ================================ */

(function( $ ) {
	$.widget("oopsdata.odParam", {
 
		// These options will be used as defaults
		options: { },
 
		// Set up the widget
		_create: function() {
			if(!this.element.is('input[param], textarea[param], a[param]'))
				return;

			var keys = (this.element.attr('param') || '').split(' ');
			var values = _.map(keys, function(k) {
				return $.util.param(k);
			});
			if(values.join('') == '') return;
			if(this.element.is('input:text, textarea')) {
				values = _.reject(values, function(v){ return !v; });
				this.element.val(values.join(','));
			} else if(this.element.is('a')) {
				for (var i = 0; i < keys.length; i++) {
					if(!values[i]) continue;
					values[i] = keys[i] + '=' + encodeURIComponent(values[i]);
				};
				values = _.reject(values, function(v){ return !v; });
				var href = this.element.attr('href') || '';
				href = href + (href.indexOf('?') > 0 ? '&' : '?') + values.join('&');
				this.element.attr('href', href);
			}
		},

		// Use the destroy method to clean up any modifications your widget has made to the DOM
		destroy: function() {
			$.Widget.prototype.destroy.call(this);
		}
	});
}(jQuery));