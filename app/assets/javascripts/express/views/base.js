//=require ../base
//=require ../helpers

/* ================================
 * The base View class for oopsdata
 * Author: Donghong Huang
 * ================================ */

$(function(){
	
	/* Base View class
	 * =========================== */
	quill.quillClass('quill.views.Base', Backbone.View, {

		/* Initialize method for all views. 
		 * DO NOT overide it. Instead, overide _initialize
		 * =========================== */
		initialize: function() {
			// find the events chain and construct the final events object.
			var events = {};
			this._proto_chain(function(pro){
				$.extend(events, pro.events);
			});
			this.events = events;
			
			// init the view
			this._proto_chain($.proxy(function(pro){
				if(pro._initialize) pro._initialize.apply(this);
			}, this));

			// render the view
			this.render();

			// add view instance to $el
			this.$el.data('view', this);
			var _setEl = this.setElement;
			this.setElement = function(newElement) {
				$(newElement).data('view', this);
				_setEl(newElement);
				return this;
			};
		},
		_initialize: function() {
			// Init method tobe overrided instead of initialize
		},

		/* render
		 * DO NOT overide it. Instead, overide _render
		 * =========================== */
		render: function() {
			this._proto_chain($.proxy(function(pro){
				if(pro._render) pro._render.apply(this);
			}, this));
		},
		_render: function() {
			// to be overrided
		},

		/* get a unique dom id and find a dom for this view
		 * ========================== */
		_domId: function(id) {
			return this.model.id + '_' + id;
		},
		_findDom: function(id) {
			return this.$('#' + this._domId(id));
		},
		
		/* handlebars helper
		 * =========================== */
		hbs: function(context, name, absolute) {
			if(absolute) {
				return $(HandlebarsTemplates['express/templates' + name](context));
			} else {
				name = name || this._ns[this._ns.length - 1];
				var names = this._ns.slice(0, this._ns.length);
				names[0] = 'express';
				names[1] = 'templates';		//change views to templates;
				names[names.length - 1] = name.uncamel();
				return $(HandlebarsTemplates[names.join('/')](context));
			}
		},

		/* replace this.el with a new element
		 * =========================== */
		replaceElement: function(newElement) {
			this.$el.replaceWith(newElement);
			this.setElement(newElement);
			return this;
		},
		
		/* append the current view to a dom
		 * =========================== */
		appendTo: function(parent) {
			this.$el.appendTo(parent);
			return this;
		},

		/* Remove the view from the document.
		 * It will call the _destroy methods
		 * =========================== */
		destroy: function() {
			this._proto_chain($.proxy(function(pro){
				if(pro._destroy) pro._destroy.apply(this);
			}, this));
			this.$el.remove();
		},
		_destroy: function() {},
		// equal to destroy
		remove: function() {
			this.destroy();
		}

	});
	
});