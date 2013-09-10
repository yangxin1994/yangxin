//=require ../../templates/editors/matrix_choice_body
//=require ui/widgets/od_item
//=require ui/widgets/od_left_icon_button

/* ================================
 * View: Matrix Choice question editor
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.editors.MatrixChoice', quill.views.editors.Base, {
		
		_initialize: function() {
			this.model.on('change:items:add', this.addItem, this);
			this.model.on('change:items:update', this.updateItem, this);
			this.model.on('change:items:remove', this.removeItem, this);
			this.model.on('change:items:move', this.moveItem, this);

			//TODO
			this.model.on('change:items:add', this.refreshExclusive, this);
			this.model.on('change:items:remove', this.refreshExclusive, this);
			this.model.on('change:items:move', this.refreshExclusive, this);

			// items
			this.model.on('change:issue:random', this.refreshRandom, this);
			this.model.on('change:issue:option_type', this.refreshItemType, this);
			this.model.on('change:issue:min_max', this.refreshMinMax, this);
			this.model.on('change:issue:exclusive', this.refreshExclusive, this);

			// sub questions
			this.model.on('change:issue:show_style_row', this.refreshSubQuestionStyle, this);
			this.model.on('change:issue:row_num_per_group', this.refreshSubQuestionGroup, this);
			this.model.on('change:issue:random_row', this.refreshSubQuestionRandom, this);
		},

		_render: function() {
			
			/* ================================
			 * Editor Left Part
			 * ================================ */

			this.hbs(this.model_issue, 'matrix_choice_body').appendTo(this.$('.q-body'));

			var setup_items = $.proxy(function(key) {
				var handler = this.model[key + 'sHandler'];

				// container
				this.$('.q-items-' + key).sortable({
					stop: $.proxy(function(event, ui) {
						handler.moveItem(ui.item.data('id'), ui.item.index());
					}, this)
				}).disableSelection();
				$.each(handler.getItems(), $.proxy(function(i, v) {
					this._renderItem(v.id, handler);
				}, this));

				// add new
				$.od.odLeftIconButton({
					text: (key == 'item') ? '添加新选项' : '添加子题目',
					width: 90
				}).appendTo(this.$('.q-new-opt-' + key)).click($.proxy(function() {
					handler.addItem();
				}, this));
			}, this);

			setup_items('item');
			setup_items('row');

			/* ================================
			 * Editor Right Part
			 * ================================ */
			this.addRightBar();

			/* sub questions
			 * ========================*/
			this.addRightBoldTitle('子问题设置');

			// style
			this.addRightItem($.od.odSelector({
				id: this._domId('show_style_slt'),
				values: ['左对齐', '中对齐', '右对齐'],
				index: this.model_issue.show_style,
				width: 120,
				onChange: $.proxy(function(index) {
					this.model.setSubQuestionStyle(index);
				}, this)
			}));
			this.refreshSubQuestionStyle();

			// group
			this.addRightItem($.od.odSelector({
				id: this._domId('group_slt'),
				values: ['不分组', '5 题一组', '10 题一组', '15 题一组', '20 题一组', '25 题一组'],
				index: Math.floor(this.model_issue.row_num_per_group / 5),
				width: 120,
				onChange: $.proxy(function(index) {
					this.model.setSubQuestionGroup(5 * index);
				}, this)
			}), true);
			this.refreshSubQuestionGroup();

			// random 
			this.addRightItem($.od.odCheckbox({
				id: this._domId('row_random_ckb'),
				checked: this.model_issue.is_row_rand,
				text: '子问题乱序',
				onChange: $.proxy(function(checked) {
					this.model.setSubQuestionRandom(checked);
				}, this)
			}));
			this.refreshSubQuestionRandom();
			
			this.addRightBar();
			
			/* items
			 * ========================*/
			this.addRightBoldTitle('选项设置');

			// Item type
			this.addRightItem($.od.odSelector({
				id: this._domId('opt_type_slt'),
				values: ['单选', '多选 - 不限制', '多选 - 固定', '多选 - 带上限', '多选 - 带下限', '多选 - 自定义'],
				index: 0,
				width: 120,
				onChange: $.proxy(function(index) {
					this.model.setItemType(index);
				}, this)
			})).css({marginTop: 0});
			
			this.addRightItem($('<div class="opt-type opt-type-2">限制选择 ' +
				'<input class="tiny-ipt" type="text" /><input class="tiny-ipt" type="text" style="display:none;"/> 项 </div>'));
			this.addRightItem($('<div class="opt-type opt-type-3">最多选择 ' +
				'<input class="tiny-ipt" type="text" style="display:none;" /><input class="tiny-ipt" type="text" /> 项 </div>'));
			this.addRightItem($('<div class="opt-type opt-type-4">至少选择 ' +
				'<input class="tiny-ipt" type="text" /><input class="tiny-ipt" type="text" style="display:none;" /> 项 </div>'));
			this.addRightItem($('<div class="opt-type opt-type-5">选择 ' +
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

			// 排他项
			var has_exclusive = this.model.hasExclusive();
			this.addRightItem($.od.odCheckbox({
				id: this._domId('exclusive_ckb'), 
				checked: has_exclusive,
				text: '设置排他项',
				onChange: $.proxy(function(checked) {
					if(!checked) {
						var items = this.model.itemsHandler.getItems();
						for (var i = 0; i < items.length; i++) {
							if(items[i].is_exclusive) {
								this.model.setExclusive(i, false);
							}
						}
					}
					checked ? this.$('.exclusive-con').show() : this.$('.exclusive-con').hide();
				}, this)
			}), true);
			this.addRightItem($('<div />').addClass('exclusive-con'), true);
			has_exclusive ? this.$('.exclusive-con').show() : this.$('.exclusive-con').hide();
			this.refreshExclusive();
			
			// 选项乱序
			this.addRightItem($.od.odCheckbox({
				id: this._domId('rand_ckb'),
				checked: false,
				text: '选项乱序',
				onChange: $.proxy(function(checked) {
					this.model.setRandom(checked);
				}, this)
			}));
			this.refreshRandom();
		},

		/* =========================
		 * Item related
		 * ========================= */
		_renderItem: function(id, handler) {
			// render a new item and add it to the container
			var item = handler.findItem(id);
			if(!item) return;
			
			var opt = $.od.odItem({
				id: this._domId(id),
				width: 280,
				value: item.content
			}).data('id', id).appendTo(this.$('.q-items-' + handler.key));
			
			var ript = opt.odItem('richInput');
			var ript_inner = ript.odRichInput('innerInput').blur($.proxy(function() {
				handler.updateItem(id, ript.odRichInput('val'));
			}, this));
			
			opt.odItem('getRemoveBtn').click($.proxy(function() {
				handler.removeItem(id);
			}, this));

			if(handler.key == 'item')
				opt.odItem('highlight', item.is_exclusive);
			
			// when enter or tab, focus on the next item
			ript_inner.keydown($.proxy(function(e) {
				if(e.which == 13 || e.which == 9) {
					opt.next().odItem('richInput').odRichInput('innerInput').focus();
					return false;
				}
			}, this));

			return opt;
		},
		addItem: function(id, handler) {
			var opt = this._renderItem(id, handler);
			if(opt.is(':visible'))
				opt.odItem('richInput').odRichInput('innerInput').focus();
		},
		updateItem: function(id, handler) {
			var item = handler.findItem(id);
			if(!item) return;
			this._findDom(id).odItem('richInput').odRichInput('val', item.content);
		},
		removeItem: function(id, handler) {
			this._findDom(id).odItem('destroy');
		},
		moveItem: function(id, target_index, handler) {
			var dom = this._findDom(id);
			if(!dom || dom.index() == target_index) return;
			dom.detach();
			if(target_index == this.model_issue.items.length - 1) {
				dom.appendTo(this.$('.q-items-' + handler.key));
			} else {
				dom.insertBefore($('od-item:eq(' + target_index + ')', this.$('.q-items-' + handler.key)));
			}
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
		
		/* Refresh exclusive
		 * ========================= */
		refreshExclusive: function() {
			var con = this.$('.exclusive-con').empty();
			var items = this.model.itemsHandler.getItems();

			var _add_a = $.proxy(function(index) {
				var opt = items[index];
				var a_dom = $('<a href="javascript:void(0);" title="选项' + (index + 1) + '" >' + (index + 1) + '</a>').appendTo(con);
				opt.is_exclusive ? a_dom.addClass('active') : true;
				a_dom.click($.proxy(function() {
					this.model.setExclusive(index, !opt.is_exclusive);
				}, this));
				a_dom.hover($.proxy(function() {
					this._findDom(opt.id).odItem('highlight', true);
				}, this), $.proxy(function() {
					if(opt.is_exclusive) return;
					this._findDom(opt.id).odItem('highlight', false);
				}, this));
			}, this);

			for (var i = 0; i < items.length; i++) {
				_add_a(i);
			}

			for (var i = 0; i < items.length; i++) {
				this._findDom(items[i].id).odItem('highlight', items[i].is_exclusive);
			};
		},

		/* Refresh random
		 * ========================= */
		refreshRandom: function() {
			this._findDom('rand_ckb').odCheckbox('val', this.model_issue.is_rand);
		},

		/* =========================
		 * Sub question related
		 * ========================= */
		refreshSubQuestionStyle: function() {
			this._findDom('show_style_slt').odSelector('index', this.model_issue.show_style);
		},
		refreshSubQuestionGroup: function() {
			this._findDom('group_slt').odSelector('index', Math.floor(this.model_issue.row_num_per_group / 5));
		},
		refreshSubQuestionRandom: function() {
			this._findDom('row_random_ckb').odCheckbox('val', this.model_issue.is_row_rand);
		}

	});
	
});