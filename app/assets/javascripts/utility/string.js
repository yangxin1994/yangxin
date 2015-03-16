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

	String.prototype.strip_tags  = function(allowed){   
		allowed = (((allowed || '') + '').toLowerCase().match(/<[a-z][a-z0-9]*>/g) || []).join('');
		var tags = /<\/?([a-z][a-z0-9]*)\b[^>]*>/gi,commentsAndPhpTags = /<!--[\s\S]*?-->|<\?(?:php)?[\s\S]*?\?>/gi;
		return this.replace(commentsAndPhpTags, '').replace(tags, function($0, $1) {
			return allowed.indexOf('<' + $1.toLowerCase() + '>') > -1 ? $0 : '';
		});
	}; 

	String.prototype.chunk = function(n) {
	    var ret = [];
	    for(var i=0, len=this.length; i < len; i += n) {
	       ret.push(this.substr(i, n))
	    }
	    return ret
	};




})(jQuery);