//=require ../../templates/editors/address_blank_body

/* ================================
 * View: Address blank question editor
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.editors.AddressBlank', quill.views.editors.Base, {
		
		_initialize: function() {
			this.model.on('change:address:has_postcode', this.refreshPostcode, this);
			this.model.on('change:address:format', this.refreshFormat, this);
		},

		_render: function() {
			
			this.$('.editor-method').hide();	// hide toggle between code and visual

			/* ================================
			 * Editor Left Part
			 * ================================ */
			
			// input preview
			this.hbs(null, 'address_blank_body').appendTo(this.$('.q-body'));

			/* ================================
			 * Editor Right Part
			 * ================================ */
			
			this.addRightBar();
			
			// format
			this.addRightTitle('地址精确到');
			
			this.addRightItem($.od.odSelector({
				id: this._domId('format_slt'),
				values: ['省', '市', '区（县）', '详细地址'],
				index: this.model.getFormat(),
				width: 120,
				onChange: $.proxy(function(index) {
					this.model.setFormat(index);
				}, this)
			}));
			this.refreshFormat();

			// postcode
			this.addRightItem($.od.odCheckbox({
				id: this._domId('postcode_ckb'), 
				checked: this.model_issue.has_postcode,
				text: '邮编',
				onChange: $.proxy(function(checked) {
					this.model.setPostcode(checked);
				}, this)
			}));
			this.refreshPostcode();

		},

		refreshFormat: function() {
			var format = this.model.getFormat();
			this._findDom('format_slt').odSelector('index', format);
			for (var i = 0; i < 4; i++) {
				(i <= format) ? this.$('.ipt-preview-' + i).show() :
					this.$('.ipt-preview-' + i).hide();
			};
		}, 

		refreshPostcode: function() {
			this._findDom('postcode_ckb').odCheckbox('val', this.model_issue.has_postcode);
			this.model_issue.has_postcode ? this.$('.ipt-preview-postcode').show() :
				this.$('.ipt-preview-postcode').hide();
		}
		
	});
	
});