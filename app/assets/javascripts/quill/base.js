/* ================================
 * OopsData namespace
 * ================================ */

$(function(){

	/* Generate namespace
	 * ======================= */
	function _namespace(namespaces) {
		if(!namespaces) 
			return null;
		var parent = (namespaces.length == 1) ? 
			window : _namespace(namespaces.slice(0, namespaces.length - 1));
		var name = namespaces[namespaces.length - 1];
		return parent[name] = parent[name] || {
			_ns: namespaces.slice(0, namespaces.length)
		};
	};
	
	/* Generate window.quill
	 * ======================= */
	$.extend(_namespace(['quill']), {
	
		quillClass: function(fullname, base, me) {
			var names = fullname.split('.');
			var namespace = _namespace(names.slice(0, names.length - 1));
			var name = names[names.length - 1];
			return namespace[name] = namespace[name] || base.extend($.extend({
				
				/* Array. names of class
				 * ['quill', 'views', 'editors', 'Choice']
				 * ======================= */
				_ns: names,

				/* String. class name
				 * 'Choice'
				 * ======================= */
				_cn: names[names.length - 1],
				
				/* Array. names of base class
				 * ['quill', 'views', 'editors', 'Base']
				 * ======================= */
				_p: base.prototype._ns,
				
				/* Function. Base class
				 * ======================= */
				_base: base,

				/* search the prototype chain from parent to child
				 * Used to call inherit-methods
				 * ======================= */
				_proto_chain: function(callback) {
					var proes = [], pro = this.constructor.prototype;
					while(pro._cn) {
						proes.push(pro);
						pro = pro._base.prototype;
					}
					for(var i=proes.length-1; i>=0; i--) {
						callback(proes[i]);
					}
				}
				
			}, me));
		}
		
	});

	// helpers
	$.extend(_namespace(['quill', 'helpers']), {});

	// modules
	$.extend(_namespace(['quill', 'modules']), {});
	
});