//=require ui/widgets/od_address_selector

/* ================================
 * View: Address blank question render
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.fillersMobile.AddressBlank', quill.views.fillersMobile.Base, {
		
		_address_selector: null,

		_render: function() {
			this._address_selector = $.od.odAddressSelector({
				precision: this.model.getFormat(),
				has_postcode: this.model_issue.has_postcode
			}).appendTo(this.$('.q-content'));
		},

		setAnswer: function(answer) {
			if(!answer) return;
			this._address_selector.odAddressSelector('val', answer);
		},
		_getAnswer: function() {
			return this._address_selector.odAddressSelector('val');
		}
		
	});
	
});
