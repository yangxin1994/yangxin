//=require ./base_with_items
//=require ui/express_widgets/od_selector
//=require ui/express_widgets/od_item
//=require ui/express_widgets/od_left_icon_button
//=require jquery.numeric

/* ================================
 * View: Choice question editor
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.editors.Choice', quill.views.editors.BaseWithItems, {
		
		_initialize: function() {
			this.model.on('change:items:add', this.refreshExclusive, this);
			this.model.on('change:items:remove', this.refreshExclusive, this);
			this.model.on('change:items:move', this.refreshExclusive, this);
			this.model.on('change:items:set_other', this.refreshExclusive, this);

			this.model.on('change:issue:option_type', this.refreshItemType, this);
			this.model.on('change:issue:min_max', this.refreshMinMax, this);
			this.model.on('change:issue:column', this.refreshColumn, this);
			this.model.on('change:issue:exclusive', this.refreshExclusive, this);
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
			this.addRightTitle('可选个数');
			
			this.addRightItem($.od.odSelector({
				id: this._domId('opt_type_slt'),
				values: ['单选 - 选项', '单选 - 下拉框', '多选 - 不限制', '多选 - 固定', '多选 - 带上限', '多选 - 带下限', '多选 - 自定义'],
				index: 0,
				width: 120,
				onChange: $.proxy(function(index) {
					this.model.setItemType(index);
				}, this)
			})).css({marginTop: 0});
			
			this.addRightItem($('<div class="opt-type opt-type-3">限制选择 ' +
				'<input class="tiny-ipt" type="text" /><input class="tiny-ipt" type="text" style="display:none;"/> 项 </div>'));
			this.addRightItem($('<div class="opt-type opt-type-4">最多选择 ' +
				'<input class="tiny-ipt" type="text" style="display:none;" /><input class="tiny-ipt" type="text" /> 项 </div>'));
			this.addRightItem($('<div class="opt-type opt-type-5">至少选择 ' +
				'<input class="tiny-ipt" type="text" /><input class="tiny-ipt" type="text" style="display:none;" /> 项 </div>'));
			this.addRightItem($('<div class="opt-type opt-type-6">选择 ' +
				'<input class="tiny-ipt" type="text" /> 到 <input class="tiny-ipt" type="text" /> 项 </div>'));
			this.$('.opt-type input').numeric({ decimal: false, negative: false }, function() {
				$(this).focus();
			});
			this.$('.opt-type').each($.proxy(function(i, v) {
				$('input', v).blur($.proxy(function(e) {
					var min = parseInt($('input:eq(0)', v).val()), max = parseInt($('input:eq(1)', v).val());
					this.model.setMinMax(min, max);
				}, this));
			}, this));
			
			this.refreshItemType();
			this.refreshMinMax();
			
			this.addRightBar(true);
			
			// Item columns
			this.addRightTitle('选项分栏', true);
			this.addRightItem($.od.odSelector({
				id: this._domId('column_slt'),
				values: ['1 栏', '2 栏', '3 栏', '4 栏', '5 栏'],
				index: this.model_issue.choice_num_per_row - 1,
				width: 120,
				onChange: $.proxy(function(index) {
					this.model.setColumnCount(index + 1);
				}, this)
			}), true).css('margin', 0);
			this.refreshColumn();
			this.addRightBar();
			
			// other item
			this._setupRightOther();
			
			// 排他项
			var has_exclusive = this.model.hasExclusive();
			this.addRightItem($.od.odCheckbox({
				id: this._domId('exclusive_ckb'), 
				checked: has_exclusive,
				text: '设置排他项',
				onChange: $.proxy(function(checked) {
					if(!checked) {
						var items = this.model.getItems();
						for (var i = 0; i < items.length; i++) {
							if(items[i].is_exclusive) {
								this.model.setExclusive(i, false);
							}
						}
						if(this.model.getOther().is_exclusive)
							this.model.setExclusive(items.length, false);
					}
					checked ? this.$('.exclusive-con').show() : this.$('.exclusive-con').hide();
				}, this)
			}), true);
			this.addRightItem($('<div />').addClass('exclusive-con'), true);
			has_exclusive ? this.$('.exclusive-con').show() : this.$('.exclusive-con').hide();
			this.refreshExclusive();
			
			// 选项乱序
			this._setupRightRandom();
		},
		
		/* Refresh Right item type
		 * ========================= */
		refreshItemType: function() {
			this._findDom('opt_type_slt').odSelector('index', this.model_issue.option_type);
			this.$('.opt-type').hide();
			this.$('.opt-type-' + this.model_issue.option_type).show();
		},
		refreshMinMax: function() {
			var min = this.model_issue.min_choice, max = this.model_issue.max_choice;
			this.$('.opt-type').each(function(i, v) {
				$('input:eq(0)', v).val(min);
				$('input:eq(1)', v).val(max);
			});
		},
		
		/* Refresh Column count
		 * ========================= */
		refreshColumn: function() {
			this._findDom('column_slt').odSelector('index', this.model_issue.choice_num_per_row - 1);
		},

		/* Refresh exclusive
		 * ========================= */
		refreshExclusive: function() {
			var con = this.$('.exclusive-con').empty();
			var items = this.model.getItems(), other_item = this.model.getOther();

			var _add_a = $.proxy(function(index) {
				var is_other = (index == items.length);
				var opt = is_other ? other_item : items[index];
				if(is_other && !opt.has_other_item) return;
				var a_dom = $('<a href="javascript:void(0);" title="选项' + (index + 1) + '" >' + (index + 1) + '</a>').appendTo(con);
				opt.is_exclusive ? a_dom.addClass('active') : true;
				a_dom.click($.proxy(function() {
					this.model.setExclusive(index, !opt.is_exclusive);
				}, this));
				a_dom.hover($.proxy(function() {
					var dom_id = is_other ? 'other_item' : opt.id;
					this._findDom(dom_id).odItem('highlight', true);
				}, this), $.proxy(function() {
					if(opt.is_exclusive) return;
					var dom_id = is_other ? 'other_item' : opt.id;
					this._findDom(dom_id).odItem('highlight', false);
				}, this));
			}, this);
			
			for (var i = 0; i <= items.length; i++) {
				_add_a(i);
			}

			for (var i = 0; i < items.length; i++) {
				this._findDom(items[i].id).odItem('highlight', items[i].is_exclusive);
			};
			this._findDom('other_item').odItem('highlight', other_item.is_exclusive);
		}
		
	});
	
});