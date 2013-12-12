//=require ui/express_widgets/od_item
//=require ui/express_widgets/od_left_icon_button

/* ================================
 * View: Base class for editor with items
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.editors.BaseWithItems', quill.views.editors.Base, {
		
		_initialize: function() {
			this.model.on('change:items:add', this.addItem, this);
			this.model.on('change:items:update', this.updateItem, this);
			this.model.on('change:items:remove', this.removeItem, this);
			this.model.on('change:items:move', this.moveItem, this);
			this.model.on('change:items:set_other', this.refreshOther, this);
			this.model.on('change:items:update_other', this.refreshOther, this);

			this.model.on('change:issue:random', this.refreshRandom, this);
		},

		_render: function() {
			
			/* ================================
			 * Editor Left Part
			 * ================================ */
			
			// items
			$('<div class="q-items" />').appendTo(this.$('.q-body')).sortable({
				stop: $.proxy(function(event, ui) {
					this.model.moveItem(ui.item.data('id'), ui.item.index());
				}, this)
			});//.disableSelection();
			$.each(this.model.getItems(), $.proxy(function(i, v) {
				this._renderItem(v.id, this.model);
			}, this));

			// other item
			var other_opt = $.od.odItem({
				id: this._domId('other_item'),
				width: 527,
				value: this.model.getOther().content,
				hideDrag: true,
				hideRemove: true
			}).appendTo($('<div class="q-other-item" />').appendTo(this.$('.q-body')));
			other_opt.odItem('richInput').odRichInput('innerInput').blur($.proxy(function() {
				this.model.updateOther(other_opt.odItem('richInput').odRichInput('val'));
			}, this));
			other_opt.odItem('other', true);
			
			// add new item
			$.od.odLeftIconButton({
				text: '添加新选项'
			}).appendTo($('<div class="q-new-opt" />').appendTo(this.$('.q-body'))).click($.proxy(function() {
				this.model.addItem();
			}, this));

			/* ================================
			 * Editor Right Part
			 * ================================ */
		},

		/* =========================
		 * Setup the right part. 
		 * ========================= */
		_setupRightOther: function() {
			this.addRightItem($.od.odCheckbox({
				id: this._domId('other_ckb'),
				checked: false,
				text: '带"其他"项',
				onChange: $.proxy(function(checked) {
					this.model.setOther(checked);
				}, this)
			}));
			this.refreshOther();
		},
		_setupRightRandom: function() {
			this.addRightItem($.od.odCheckbox({
				id: this._domId('rand_ckb'),
				checked: false,
				text: '选项乱序',
				onChange: $.proxy(function(checked) {
					this.model.setRandom(checked);
				}, this)
			}), true);
			this.refreshRandom();
		},
		
		/* Refresh other
		 * ========================= */
		refreshOther: function() {
			this._findDom('other_ckb').odCheckbox('val', this.model.getOther().has_other_item);
			var other_opt = this._findDom('other_item');
			other_opt.odItem('highlight', this.model.getOther().is_exclusive);
			other_opt.odItem('richInput').odRichInput('val', this.model.getOther().content);
			this.model.getOther().has_other_item ? 
				this.$('.q-other-item').show() : this.$('.q-other-item').hide();
		},
		
		/* Refresh random
		 * ========================= */
		refreshRandom: function() {
			this._findDom('rand_ckb').odCheckbox('val', this.model_issue.is_rand);
		},

		/* Items related
		 * ========================= */
		_renderItem: function(id, handler) {
			// render a new item and add it to the
			var item = handler.findItem(id);
			if(!item) return;
			
			var opt = $.od.odItem({
				id: this._domId(id),
				width: 530,
				value: item.content
			}).data('id', id).appendTo(this.$('.q-items'));
			
			var ript = opt.odItem('richInput');
			var ript_inner = ript.odRichInput('innerInput').blur($.proxy(function() {
				handler.updateItem(id, ript.odRichInput('val'));
			}, this));
			
			opt.odItem('getRemoveBtn').click($.proxy(function() {
				handler.removeItem(id);
			}, this));

			opt.odItem('highlight', item.is_exclusive);

			// when enter or tab, focus on the next item
			ript_inner.keydown($.proxy(function(e) {
				if(e.which == 13 || e.which == 9) {
					var next_dom = opt.next();
					if(next_dom.length == 0)
						next_dom = this.$('.q-other-item .od-item');
					next_dom.odItem('richInput').odRichInput('innerInput').focus();
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
			if(target_index == handler.getItems().length - 1) {
				dom.appendTo(this.$('.q-items'));
			} else {
				dom.insertBefore(this.$('od-item:eq(' + target_index + ')'));
			}
		}

	});
	
});