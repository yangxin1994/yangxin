/* ================================
 * Extend Array prototype to support some methods
 * ================================ */
(function($){

	/* Remvoe a element from an array. The first element.
	 * ============================== */
	Array.prototype.remove = function(v) {
		this.splice(this.indexOf(v) == -1 ? this.length : this.indexOf(v), 1);
	};

	/* Skip the first blanks in the array
	 * ============================== */
	Array.prototype.skipBlank = function() {
		var index = 0;
		for (; index < this.length; index++) {
			if(this[index]) break;
		};
		return this.slice(index, this.length);
	};
	
})(jQuery);