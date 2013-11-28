//=require ../../templates/editors/sort_min_max

/* ================================
 * View: Sort question editor
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.editors.Sort', quill.views.editors.BaseWithItems, {
		
		_initialize: function() {
			this.model.on('change:issue:min_max', this.refreshMinMax, this);
		},

		_render: function() {
			/* ================================
			 * Editor Left Part
			 * ================================ */
			
			/* ================================
			 * Editor Right Part
			 * ================================ */

			this.addRightBar();
			
			// Item type
			this.addRightTitle('排序数量');
			
			this.addRightItem($.od.odSelector({
				id: this._domId('item_count_slt'),
				values: ['定值', '设上限', '设下限'],
				index: 0,
				width: 120,
				onChange: $.proxy(function(index) {
					var v = this.model_issue.min;
					if(v < 0) v = this.model_issue.max;
					switch(index) {
						case 0: this.model.setMinMax(v, v); break;
						case 1: this.model.setMinMax(-1, v); break;
						case 2: this.model.setMinMax(v, -1); break;
					}
				}, this)
			})).css({marginTop: 0});

			this.addRightItem(this.hbs(null, 'sort_min_max'));
			this.$('.item-count input').numeric({ decimal: false, negative: false }, function() {
				$(this).focus();
			});
			this.$('.item-count input').each($.proxy(function(i, ipt) {
				var $ipt = $(ipt);
				$ipt.blur($.proxy(function(e) {
					var value = parseInt($ipt.val());
					if(isNaN(value)) value = this.model.itemCount();
					var min = max = -1;
					switch(i) {
						case 0: min = max = value; break;
						case 1: max = value; break;
						case 2: min = value; break;
						case 3: break;
					}
					this.model.setMinMax(min, max);
				}, this));
			}, this));

			this.refreshMinMax();
			
			this.addRightBar(true);
			
			// other item
			this._setupRightOther();
			
			// 选项乱序
			this._setupRightRandom();
		},

		refreshMinMax: function() {
			this.$('.item-count >div').hide();
			var index = 0, value = this.model_issue.min;
			if(this.model_issue.min < 0) {
				index = 1;
				value = this.model_issue.max;
			} else if(this.model_issue.max < 0) {
				index = 2;
			}
			this.$('.item-count >div:eq(' + index + ')').show();
			this.$('.item-count >div:eq(' + index + ') input').val(value);
			this._findDom('item_count_slt').odSelector('index', index);
		}
		
	});
	
});