//=require ../../templates/editors/const_sum_sum

/* ================================
 * View: ConstSum question editor
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.editors.ConstSum', quill.views.editors.BaseWithItems, {
		
		_initialize: function() {
			this.model.on('change:issue:show_style', this.refreshStyle, this);
			this.model.on('change:issue:sum', this.refreshSum, this);
		},

		_render: function() {
			/* ================================
			 * Editor Left Part
			 * ================================ */
			
			/* ================================
			 * Editor Right Part
			 * ================================ */

			this.addRightBar();
			
			// show style
			// this.addRightTitle('显示样式');
			
			// this.addRightItem($.od.odSelector({
			// 	id: this._domId('show_style_slt'),
			// 	values: ['滑竿拖动', '数值填充'],
			// 	index: this.model_issue.show_style,
			// 	width: 120,
			// 	onChange: $.proxy(function(index) {
			// 		this.model.setStyle(index);
			// 	}, this)
			// })).css({marginTop: 0});

			// this.refreshStyle();

			// this.addRightBar();

			// sum
			this.addRightTitle('比重总和');

			var index = 3;
			switch(this.model_issue.sum) {
				case 10: index = 0; break;
				case 100: index = 1; break;
				case 1000: index = 2; break;
			}
			this.addRightItem($.od.odSelector({
				id: this._domId('sum_slt'),
				values: ['10', '100', '1000', '自定义'],
				index: index,
				width: 120,
				onChange: $.proxy(function(index) {
					if(index < 3) {
						this.$('.const-sum-sum').hide();
						this.model.setSum(Math.pow(10, index + 1));
					} else {
						this.$('.const-sum-sum').show();
					}
				}, this)
			}));

			this.addRightItem(this.hbs(this.model_issue, 'const_sum_sum'));
			this.$('.const-sum-sum input').numeric({ decimal: false, positive: true }, function() {
				$(this).focus();
			});
			this.$('.const-sum-sum input').blur($.proxy(function(e) {
				this.model.setSum(parseInt($(e.target).val()));
			}, this));
			if(index != 3) this.$('.const-sum-sum').hide();

			this.addRightBar(true);
			
			// other item
			this._setupRightOther();
			
			// 选项乱序
			this._setupRightRandom();
		},

		refreshStyle: function() {
			this._findDom('show_style_slt').odSelector('index', this.model_issue.show_style);
		},

		refreshSum: function() {
			this.$('.const-sum-sum input').val(this.model_issue.sum);
		}

	});
	
});