/* ================================
 * Model: Base Question model with items
 * ================================ */

$(function(){

	quill.quillClass('quill.models.questions.BaseWithItems', quill.models.questions.Base, {

		_initialize: function() {
			$.extend(this, quill.modules.items(this, 'item', true, this._newItem, this._itemCountChanged));
			$.extend(this, quill.modules.rand(this, this.issue));
		},

		/* Generate a new item. To be overrided
		 * =========================== */
		_newItem: function(model, content) {
			//to be override
		},

		/* Hook function for item count changing
		 * =========================== */
		_itemCountChanged: function(model) {
			//to be override
		},

		/* Serialize the model to array codes. 
		 * Deserialize the model from array codes.
		 * =========================== */
		_serialize: function() {
			return this._serialize_items();
		},
		_deserialize: function(item_codes) {
			this._deserialize_items(item_codes);
		}

	});

});