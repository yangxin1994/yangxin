/* ================================
 * The base class for all oopsdata widgets
 * Author: Donghong Huang
 * ================================ */

(function($) {

	var _ns = "oopsdata";

	/* The widget base class for all oopsdata plugin
	 * ================================= */
	$.widget(_ns + ".base", {
	
		// ERROR！ this._super_prototype will always refer to the direct parent class
		/* Super prototype and call super method
		 * =============================== */
		// _super_prototype: $.Widget.prototype,
		// _super: function(func, args) {
		// 	this._super_prototype[func].apply(this, 
		// 		Array.prototype.slice.call(arguments, 1));
		// },
		
		/* Set up the widget. 
		 * NEVER OVERRIDE _create! Instead, override _createEl.
		 * ================================ */
		_create: function() {
			this._element = this.element;
			this._createEl();
			if(this.options.id)
				this.element.attr('id', this.options.id);
			this.element.data(this.widgetName, this._element.data(this.widgetName));
			this._element.data(this.widgetName + ".element", this.element);
		},
		_createEl: function() {
			// to be override
			this.element = $('<div />');
		},
		
		/* Destroy the widget.
		 * NEVER OVERRIDE destroy! Instead, override _destroy
		 * ================================ */
		destroy: function() {
			this._destroy();
			
			if(this._element != this.element) {
				this.element.remove();
				this.element = this._element;
			}
			this._element = null;
			
			$.Widget.prototype.destroy.call(this);
		},
		_destroy: function() { },
		
		/* Find element(s) in this plugin
		 * =============================== */
		_find: function(selector) {
			return this.element.find(selector);
		},
		
		/* handlebars helper
		 * =========================== */
		hbs: function(context, name) {
			return $(HandlebarsTemplates["ui/widgets/_templates/" + (name ? name : this.widgetName).uncamel()](context));
		}
	});
	
	/* Namespace for shortcut factory methods
	 * ================================= */
	$.od = $.od || {};
	
	/* OopsData widget factory
	 * ================================= */
	$.odWidget = function(widgetName, baseWidgetPrototype, widgetPrototype) {
		
		if(!widgetName) return;
		
		// run jquery ui widget factory
		var args = Array.prototype.slice.call(arguments, 0);
		args[0] = _ns + "." + args[0];
		if(args.length == 1 || typeof args[1] !== "string") {
			args.splice(1, 0, 'base');
		}
		args[1] = $[_ns][args[1]];
		if(!args[2]) args[2] = {};
		// $.extend(args[2], {
		// 	_super_prototype: args[1].prototype
		// });
		$.widget.apply(this, args);

		// generate shortcut factory method for widget
		$.od[widgetName] = function(options) {
			return $('<div />')[widgetName](options).data(widgetName + ".element");
		};
	};
	
})(jQuery);
