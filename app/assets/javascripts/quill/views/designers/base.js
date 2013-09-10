//=require ../base
//=require ../fillers
//=require ../editors
//=require quill/templates/designers/base
//=require quill/templates/designers/q_render
//=require ui/widgets/od_tip
//=require ui/widgets/od_waiting
//=require ui/widgets/od_white_button

/* ================================
 * Base class for question designer
 * ================================ */

$(function(){
	
	/* Base question designer class
	 * options:
	 *    index: int
	 *    remove: function() {}
	 *    pagination: function() {}
	 *    saved: function() {}
	 *    onOpenEditor: function() {}
	 *    onOpenRender: function() {}
	 *		locked: bool
	 * =========================== */
	quill.quillClass('quill.views.designers.Base', quill.views.Base, {

		_initialize: function() {},

		_render: function() {
			this.replaceElement(this.hbs(this.model.toJSON(), 'base'));
			this.openRender();
		},

		refreshIndex: function(index) {
			if(index >= 0) this.options.index = index;
			if(this._fl) this._fl.refreshIndex(index);
			if(this._ed) this._ed.refreshIndex(index);
		},

		/* Toggle to render status
		 * =========================== */
		_rd: null,
		_rd_btns: null,
		_fl: null,
		openRender: function() {
			// 1. close editor
			if(this._ed) {
				this._ed.remove();
				this._ed = null;
			}
			// 2. new render
			this._rd = this.hbs(null, 'q_render').appendTo(this.$el);
			this._fl = new quill.views.fillers[this._cn]({
				index: this.options.index,
				model: this.model
			}).appendTo($('.q-render-mid', this._rd));
			var btns_con = $('.q-render-btns', this._rd);
			var confirm_con = $('.q-render-btns-confirm', this._rd);
			var _start_edit = $.proxy(function() {
				this.openEditor();
			}, this);
			this._rd.dblclick(_start_edit);
			$('.q-render-btns-con', this._rd).dblclick(function(e) { e.stopPropagation(); });
			var buttons = [];
			this._rd_btns = $.od.odIconButtons({
				buttons:	this.options.locked ? [{
		 			name: 'pagination',
		 			info: '从此处开始新页',
		 			click: $.proxy(function(){
						if(this.options.pagination) 
							this.options.pagination();
					}, this)
				}] : [{
		 			name: 'edit',
		 			info: '编辑',
		 			click: _start_edit
		 		}, {
		 			name: 'del',
		 			info: '删除',
		 			click: function() {
						btns_con.hide();
						confirm_con.show();
					}
		 		}, {
		 			name: 'pagination',
		 			info: '从此处开始新页',
		 			click: $.proxy(function(){
						if(this.options.pagination) 
							this.options.pagination();
					}, this)
		 		}]
			}).appendTo(btns_con);
			$.od.odWhiteButton({ text: '确定删除' }).appendTo(confirm_con).click($.proxy(function() {
				var waiting = $.od.odWaiting({
					message: '正在删除',
					contentId: this._rd
				}).odWaiting('open');
				this.options.remove(function() {
					// failed
					btns_con.show();
					confirm_con.hide();
					if(waiting) waiting.odWaiting('destroy');
				});
			}, this));
			$('<a href="javascript:void(0);" style="margin: 0 10px;" />').text('取消').appendTo(confirm_con).click(function() {
				btns_con.show();
				confirm_con.hide();
			});

			// 3. call callback
			if(this.options.onOpenRender)
				this.options.onOpenRender();
		},

		/* Toggle to editor status
		 * =========================== */
		_ed: null,
		openEditor: function() {
			if(this.options.locked) return;
			// 1. remove render
			if(this._fl) {
				this._fl.remove();
				this._fl = null;
				this._rd.remove();
				this._rd_btns.odIconButtons('destroy');	// Remember to destroy odIconButton. Or its tooltip will keep visiable
			}

			// 2. new editor
			var temp_model = this.model.clone();
			var _cancel = $.proxy(function() {
				this.openRender();
			}, this);
			var _confirm = $.proxy(function() {
				this.model = temp_model;
				if(this.options.saved) {
					this.options.saved(temp_model);
				}
				_cancel();
			}, this);
			this._ed = new quill.views.editors[this._cn]({
				index: this.options.index,
				model: temp_model,
				cancel: _cancel,
				confirm: _confirm
			}).appendTo(this.$el);

			// 3. call callback
			if(this.options.onOpenEditor)
				this.options.onOpenEditor();
		}
	});

});
