/* ================================
 * Provide some utility methods
 * ================================ */
(function($){

	$.util = $.util || {};

	/* Generate a guid
	 * http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript
	 * ============================== */
	$.util.guid = function() {
		return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
			return (Math.random()*16|0, v = c == 'x' ? r : (r&0x3|0x8)).toString(16);
		});
	};

	/* Generate a unique long id
	 * http://www.sitepoint.com/forums/showthread.php?318819-Unique-ID-in-Javascript
	 * NOTE: the id is pseudo-unique
	 * ============================== */
	$.util.uid = function() {
		return (Math.floor((Math.random() + Math.random() + Math.random() + Math.random()) * Math.pow(10, 16))
			+ (new Date()).getTime());
	};

	/* Print a value, make 0-9 starts with a '0'
	 * =============================== */
	$.util.printNumber = function(int_value) {
		return ((int_value >= 0 && int_value < 10) ? '0' : '') + int_value;
	};

	/* Print a value, make 0-9 starts with a '0'
	 * =============================== */
	$.util.round = function(value, precision) {
		var p = Math.pow(10, precision);
		return Math.round(value * p) / p;
	};

	/* Max and min time for time widget
	 * =============================== */
	$.util.MIN_TIME = (new Date(1900, 0, 1, 0, 0, 0, 0)).getTime();
	$.util.MAX_TIME = (new Date(2049, 11, 31, 23, 59, 59, 999)).getTime();

	/* Print a friendly time
	 * =============================== */
	$.util.printTimeFriendly = function(time_in_seconds) {
		var text = time_in_seconds < 0 ? '负' : '';
		var seconds = Math.abs(time_in_seconds);
		var minutes = Math.floor(seconds / 60 + 0.2);
		if(minutes > 0) {
			var hours = Math.floor(minutes / 60); 
			if(hours > 0)
				text += hours + '小时';
			text += (minutes % 60) + '分钟';
		} else {
			// text += seconds + ' 秒钟';
			text += '不到1分钟';
		}
		return text;
	};
	$.util.printDate = function(date) {
		return (date == null) ? null : date.getFullYear() + '-' + (date.getMonth() + 1) + '-' + date.getDate();
	};

	/* Get and set param and anchor
	 * ================================ */
	$.util.param = function(vKey, vValue) {
		if(vValue === undefined) {
			// get
			if(vKey == null) return null;
			var searchstr = location.search;
			if(searchstr==null || $.trim(searchstr)=="") return null;
			var params = searchstr.substr(1, searchstr.length-1).split("&");
			for(var i=0; i<params.length; i++) {
				var keyandvalue = params[i].split("=");
				if(keyandvalue[0]==vKey) 
					return unescape(keyandvalue[1]);
			}
			return null;
		} else {
			// set
			if(arguments == null) return;
			var ht = {};
			// old params
			var searchstr = location.search;
			if(searchstr != null) {
				var params = searchstr.substr(1, searchstr.length-1).split("&");
				for(var i=0; i<params.length; i++) {
					if(params[i] == null || $.trim(params[i]) == "")
						continue;
					var keyandvalue = params[i].split("=");
					if($.trim(keyandvalue[0]) != "")
						ht[keyandvalue[0]] = unescape(keyandvalue[1]);
				}
			}
			// new params
			for (var i=0; i+1<arguments.length; i+=2) {
				var key = $.trim(arguments[i]), value = arguments[i+1];
				if(key==null || key=="")
					continue;
				ht[key] = value;
			}
			location.search = (function() {
				var retval = "";
				$.each(ht, function(vName, vValue) {
					if(vValue == null) return;
					retval += "&" + vName + "=" + escape(vValue);
				});
				if(retval!="")
					retval = retval.substr(1, retval.length-1);
				return retval;
			})();

		}
	};

	$.util.anchor = function(vKey, vValue) {
		if(vValue === undefined) {
			// get
			if(vKey == null) return null;
			var anchorstr = jQuery.trim(location.hash);
			if(anchorstr==null || anchorstr=="") return null;
			var params = anchorstr.substr(1, anchorstr.length-1).split("&");
			for(var i=0; i<params.length; i++) {
				var keyandvalue = params[i].split("="),
					key = jQuery.trim(keyandvalue[0]),
					value = unescape(keyandvalue[1]);
				if(key==vKey) return value;
			}
			return null;
		} else {
			if(arguments == null) return;
			var ht = {};
			// old params
			var searchstr = location.hash;
			if(searchstr != null && searchstr.length > 0) {
				var params = searchstr.substr(1, searchstr.length-1).split("&");
				for(var i=0; i<params.length; i++) {
					var p = jQuery.trim(params[i]);
					if(p == null || p == "") continue;
					var keyandvalue = p.split("="),
						key = jQuery.trim(keyandvalue[0]),
						value = unescape(keyandvalue[1]);
					if(key != "") ht[key] = value;
				}
			}
			// new params
			for (var i=0; i+1<arguments.length; i+=2) {
				var key = jQuery.trim(arguments[i]), value = arguments[i+1];
				if(key==null || key=="") continue;
				ht[key] = value;
			}
			location.hash = (function() {
				var retval = "";
				$.each(ht, function(vName, vValue) {
					if(vValue == null) return;
					retval += "&" + vName + "=" + escape(vValue);
				});
				if(retval.length > 0) retval = retval.substr(1, retval.length-1);
				return retval;
			})();
		}
	};

	/* Disable and enable doms
	 * =============================== */
	$.extend($.util, {
		disable: function(doms) {
			$.each(arguments, function(i, v) {
				v.attr('disabled', 'disabled');
			});
		},
		enable: function(doms) {
			$.each(arguments, function(i, v) {
				v.attr('disabled', null);
			});
		}
	});

})(jQuery);