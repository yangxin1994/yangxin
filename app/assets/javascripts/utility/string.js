/* ================================
 * Extend jQuery to support some string methods
 * Author: Donghong Huang
 * ================================ */
(function($){

	/* change abc_def to abcDef or AbcDef (if camelHead == true)
	 * ============================== */
	String.prototype.camel = function(camelHead) {
		return camelHead ? this.replace(/(^|_)([a-z])/g, function ($0, $1, $2) {
			return $2.toUpperCase();
		}) : this.replace(/(_)([a-z])/g, function ($0, $1, $2) {
			return $2.toUpperCase();
		});
	};

	/* change AbcDef to abc_def
	 * ============================== */
	String.prototype.uncamel = function() {
		return this.replace(/([^A-Z])([A-Z])/g, function ($0, $1, $2) {
			return $1 + "_" + $2.toLowerCase();
		}).toLowerCase();
	};

	/* start with other string
	 * ============================== */
	String.prototype.startsWith = function(prefix) {
		return this.indexOf(prefix) == 0;
	};


	String.prototype.replaceAll  = function(s1,s2){   
		return this.replace(new RegExp(s1,"gm"),s2);   
	};  


})(jQuery);