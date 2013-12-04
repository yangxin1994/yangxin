//=require ../../templates/editors/number_blank_body
//=require ../../templates/editors/number_blank_min_max
//=require ../../templates/editors/number_blank_unit

/* ================================
 * View: Number blank question editor
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.editors.NumberBlank', quill.views.editors.Base, {
		
		_initialize: function() {
			this.model.on('change:number:min_max', this.refreshMinMax, this);
			this.model.on('change:number:unit', this.refreshUnit, this);
			this.model.on('change:number:unit_location', this.refreshUnitLocation, this);
			this.model.on('change:number:precision', this.refreshPrecision, this);
		},

		_render: function() {
			
			this.$('.editor-method').hide();	// hide toggle between code and visual

			/* ================================
			 * Editor Left Part
			 * ================================ */
			
			// input preview
			this.hbs(null, 'number_blank_body').appendTo(this.$('.q-body'));

			/* ================================
			 * Editor Right Part
			 * ================================ */
			
			// precision
			this.addRightBar();
			this.addRightTitle('数值精度');
			
			this.addRightItem($.od.odSelector({
				id: this._domId('precision_slt'),
				values: ['整数', '小数（0.0）', '0.00', '0.000', '0.0000'],
				index: this.model_issue.precision,
				width: 120,
				onChange: $.proxy(function(index) {
					this.model.setPrecision(index);
				}, this)
			}));
			this.refreshPrecision();
			
			// min max
			this.addRightBar();
			this.addRightTitle('数值范围');
			
			this.addRightItem($.od.odSelector({
				id: this._domId('min_max_slt'),
				values: ['不限制', '设下限', '设上限', '自定义'],
				index: this.model.getMinMaxType(),
				width: 120,
				onChange: $.proxy(function(index) {
					var min = this.model.MIN_INT, max = this.model.MAX_INT;
					switch(index) {
						case 0: break;
						case 1: min = (this.model_issue.min_value == this.model.MIN_INT ? 0 : this.model_issue.min_value); break;
						case 2: max = (this.model_issue.max_value == this.model.MAX_INT ? 100 : this.model_issue.max_value); break;
						case 3: 
							min = (this.model_issue.min_value == this.model.MIN_INT ? 0 : this.model_issue.min_value); 
							max = (this.model_issue.max_value == this.model.MAX_INT ? 100 : this.model_issue.max_value);
							break;
					}
					this.model.setMinMax(min, max);
				}, this)
			}));

			this.addRightItem(this.hbs(null, 'number_blank_min_max'));
			this.$('.number-blank-min-max input').numeric({}, function() {
				$(this).focus();
			});
			this.$('.number-blank-min-max input').each($.proxy(function(i, ipt) {
				var $ipt = $(ipt);
				$ipt.blur($.proxy(function(e) {
					var min = this.model.MIN_INT, max = this.model.MAX_INT;
					var $p = $ipt.parent();
					switch($p.index()) {
						case 0: min = parseInt($('input', $p).val()); break;
						case 1: max = parseInt($('input', $p).val()); break;
						case 2: min = parseInt($('input:eq(0)', $p).val()); max = parseInt($('input:eq(1)', $p).val()); break;
					}
					this.model.setMinMax(min, max);
				}, this));
			}, this));
			
			this.refreshMinMax();

			// unit
			this.addRightBar(true);

			this.addRightTitle('设置单位', true);
			
			this.addRightItem($.od.odSelector({
				id: this._domId('unit_slt'),
				values: ['无单位', '单位后置', '单位前置'],
				index: this.model_issue.unit_location,
				width: 120,
				onChange: $.proxy(function(index) {
					this.model.setUnitLocation(index);
				}, this)
			}), true);

			this.addRightItem(this.hbs(this.model_issue, 'number_blank_unit'), true);
			this.$('.number-blank-unit-edit input').blur($.proxy(function(e) {
				this.model.setUnit($.trim($(e.target).val()));
			}, this));
			
			this.refreshUnitLocation();
			this.refreshUnit();
		},

		refreshPrecision: function() {
			this._findDom('precision_slt').odSelector('index', this.model_issue.precision);
		},

		refreshMinMax: function() {
			var type = this.model.getMinMaxType();
			this._findDom('min_max_slt').odSelector('index', type);
			this.$('.number-blank-min-max > div').hide();
			switch(type) {
				case 0: break;
				case 1: this.$('.number-blank-min-max > div:eq(0) input').val(this.model_issue.min_value); break;
				case 2: this.$('.number-blank-min-max > div:eq(1) input').val(this.model_issue.max_value); break;
				case 3: 
					this.$('.number-blank-min-max > div:eq(2) input:eq(0)').val(this.model_issue.min_value);
					this.$('.number-blank-min-max > div:eq(2) input:eq(1)').val(this.model_issue.max_value);
					break;
			}
			if(type > 0) {
				this.$('.number-blank-min-max > div:eq(' + (type - 1) + ')').show();
			}
		}, 

		refreshUnitLocation: function() {
			this._findDom('unit_slt').odSelector('index', this.model_issue.unit_location);
			this.$('.number-blank-unit').hide();
			if(this.model_issue.unit_location > 0) {
				this.$('.number-blank-unit-edit').show();
				this.$('.number-blank-unit:eq(' + (2 - this.model_issue.unit_location) + ')').show();
			} else {
				this.$('.number-blank-unit-edit').hide();
			}
		},

		refreshUnit: function() {
			this.$('.number-blank-unit-edit input').val(this.model_issue.unit);
			this.$('.number-blank-unit').text(this.model_issue.unit);
		}

	});
	
});