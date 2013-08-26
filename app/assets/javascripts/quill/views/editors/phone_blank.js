//=require ../../templates/editors/phone_blank_body

/* ================================
 * View: Phone blank question editor
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.editors.PhoneBlank', quill.views.editors.Base, {
		
		_initialize: function() {
			this.model.on('change:phone:phone_type', this.refreshPhoneType, this);
		},

		_render: function() {
			
			this.$('.editor-method').hide();	// hide toggle between code and visual

			/* ================================
			 * Editor Left Part
			 * ================================ */
			
			// input preview
			this.hbs(null, 'phone_blank_body').appendTo(this.$('.q-body'));

			/* ================================
			 * Editor Right Part
			 * ================================ */
			
			this.addRightBar();
			
			// phone type
			this.addRightTitle('电话类型');
			
			this.addRightItem($.od.odSelector({
				id: this._domId('phone_type_slt'),
				values: ['座机', '手机', '座机或手机'],
				index: this.model.getPhoneType(),
				width: 120,
				onChange: $.proxy(function(index) {
					this.model.setPhoneType(index);
				}, this)
			}));
			this.refreshPhoneType();
		},

		refreshPhoneType: function() {
			this._findDom('phone_type_slt').odSelector('index', this.model.getPhoneType());
			this.$('.preview-title-txt').hide();
			this.$('.preview-title-txt:eq(' + this.model.getPhoneType() + ')').show();
		}
		
	});
	
});