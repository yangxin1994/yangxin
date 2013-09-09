//=require ../../templates/editors/text_blank_body
//=require ../../templates/editors/text_blank_min_max

/* ================================
 * View: Text blank question editor
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.editors.TextBlank', quill.views.editors.Base, {
		
		_initialize: function() {
			this.model.on('change:text:min_max', this.refreshMinMax, this);
			this.model.on('change:text:multiple', this.refreshMultiple, this);
			this.model.on('change:text:size', this.refreshSize, this);
		},

		_render: function() {
			
			this.$('.editor-method').hide();	// hide toggle between code and visual

			/* ================================
			 * Editor Left Part
			 * ================================ */
			
			// input preview
			this.hbs(null, 'text_blank_body').appendTo(this.$('.q-body'));

			/* ================================
			 * Editor Right Part
			 * ================================ */
			
			this.addRightBar();
			
			// min max
			this.addRightTitle('字数限制');
			
			this.addRightItem($.od.odSelector({
				id: this._domId('min_max_slt'),
				values: ['不限制', '设下限', '设上限', '自定义'],
				index: this.model.getMinMaxType(),
				width: 120,
				onChange: $.proxy(function(index) {
					var min = -1, max = -1;
					switch(index) {
						case 0: break;
						case 1: min = (this.model_issue.min_length < 0 ? 5 : this.model_issue.min_length); break;
						case 2: max = (this.model_issue.max_length < 0 ? 100 : this.model_issue.max_length); break;
						case 3: 
							min = (this.model_issue.min_length < 0 ? 5 : this.model_issue.min_length); 
							max = (this.model_issue.max_length < 0 ? 100 : this.model_issue.max_length);
							break;
					}
					this.model.setMinMax(min, max);
				}, this)
			}));

			this.addRightItem(this.hbs(null, 'text_blank_min_max'));
			this.$('.min-max input').numeric({ decimal: false, negative: false }, function() {
				$(this).focus();
			});
			this.$('.min-max input').each($.proxy(function(i, ipt) {
				var $ipt = $(ipt);
				$ipt.blur($.proxy(function(e) {
					var min = -1, max = -1;
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

			// size and multiple
			this.addRightBar();

			this.addRightTitle('输入框尺寸');
			
			this.addRightItem($.od.odSelector({
				id: this._domId('multiple_slt'),
				values: ['单行', '多行'],
				index: this.model_issue.has_multiple_line ? 1 : 0,
				width: 120,
				onChange: $.proxy(function(index) {
					this.model.setMultiple(index == 1);
				}, this)
			}));
			this.refreshMultiple();

			this.addRightItem($.od.odSelector({
				id: this._domId('size_slt'),
				values: ['小', '中', '大'],
				index: this.model_issue.size,
				width: 120,
				onChange: $.proxy(function(index) {
					this.model.setSize(index);
				}, this)
			}));
			this.refreshSize();

		},

		refreshMinMax: function() {
			var type = this.model.getMinMaxType();
			this._findDom('min_max_slt').odSelector('index', type);
			this.$('.min-max > div').hide();
			switch(type) {
				case 0: break;
				case 1: this.$('.min-max > div:eq(0) input').val(this.model_issue.min_length); break;
				case 2: this.$('.min-max > div:eq(1) input').val(this.model_issue.max_length); break;
				case 3: 
					this.$('.min-max > div:eq(2) input:eq(0)').val(this.model_issue.min_length);
					this.$('.min-max > div:eq(2) input:eq(1)').val(this.model_issue.max_length);
					break;
			}
			if(type > 0) {
				this.$('.min-max > div:eq(' + (type - 1) + ')').show();
			}
		}, 

		refreshSize: function() {
			this._findDom('size_slt').odSelector('index', this.model_issue.size);
			var width = 350;
			switch(this.model_issue.size) {
				case 0: width = 230; break;
				case 1: width = 350; break;
				case 2: width = 500; break;
			}
			this.$('.text-blank-preview').css('width', width + 'px');
		},

		refreshMultiple: function() {
			this._findDom('multiple_slt').odSelector('index', this.model_issue.has_multiple_line ? 1 : 0);
			this.$('.text-blank-preview').css('height', (this.model_issue.has_multiple_line ? 150 : 27 ) + 'px');
		}
		
	});
	
});