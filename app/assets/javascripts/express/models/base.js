//=require ../base
//=require ../helpers

/* ================================
 * The base model class for oopsdata
 * ================================ */

$(function(){
	
	/* Namespace for quill.models
	 * =========================== */
	quill.quillClass('quill.models.Base', Backbone.Model, {

		__isModel: true,

		idAttribute: '_id',
		
		/* defaults for model.
		 * IMPORTANT! overide _defaults instead of defaults provided by backbones.js
		 * =========================== */
		defaults: function() {
			var defaults = {};
			this._proto_chain(function(pro){
				$.extend(defaults, pro._defaults);
			});
			return $.extend(true, {}, defaults);
		},
		_defaults: null,

		/* initialize model
		 * IMPORTANT! overide _initialize
		 * =========================== */
		initialize: function() {
			this._proto_chain($.proxy(function(pro){
				if(pro._initialize) pro._initialize.apply(this);
			}, this));
		},
		_initialize: function() {
			// to be override
		}
		
	});
	
});