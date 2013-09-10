/* ================================
 * Handle callback function
 * ================================ */
(function($){

	/* ensure the callback is a object and has success+error method
	 */
	$.ensureCallback = function (callback) {
		callback = callback || {};
		if(_.isFunction(callback)) {
			callback = {
				success: callback
			}
		}
		callback = $.extend({
			success: function() {},
			error: function() {}
		}, callback);

		callback._before = callback.before || function() {};
		callback._after = callback.after || function() {};
		if(callback.both)
			console.warn('The method of "both" in callback is deprecated. Use "after" instead. ');
		callback._both = callback.both || function() {};
		if(callback.success) {
			callback._success = callback.success;
			callback.success = function() {
				callback._before.apply(this, arguments);
				callback._success.apply(this, arguments);
				callback._after.apply(this, arguments);
				callback._both.apply(this, arguments);
			};
		}
		if(callback.error) {
			callback._error = callback.error;
			callback.error = function() {
				callback._before.apply(this, arguments);
				callback._error.apply(this, arguments);
				callback._after.apply(this, arguments);
				callback._both.apply(this, arguments);
			};
		}
		delete callback.before;
		delete callback.after;
		delete callback.both;
		return callback;
	}

})(jQuery);