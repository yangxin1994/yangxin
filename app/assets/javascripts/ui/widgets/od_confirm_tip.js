//=require ./_base
//=require ./_templates/od_confirm_tip
//=require ./od_tip

(function($) {

	$.odWidget('odConfirmTip', {
		
		/* The default setting for plugin
		 * ================================ */
		options: {
			target: null,
			text: '确定',
			confirm: function(callback) {},
			hide: function() {}
		},
		
		/* Set up the widget
		 * ================================ */
		_createEl: function() {
			if(!this.options.target) {
				throw 'Target of odConfirmTip should not be null';
				return;
			}
			var target = $(this.options.target);
			var confirm_dom = this.hbs(this.options);
			this._tip = $.od.odTip({
				title: false,
				tipContent: confirm_dom,
				clickBtn: target,
				hideCallback: this.options.hide
			});

			var ok_btn = $('.ok-btn', confirm_dom), cancel_btn = $('.cancel-btn', confirm_dom);
			cancel_btn.click($.proxy(function() {
				this._tip.odTip('hide');
			}, this));
			ok_btn.click($.proxy(function() {
				$.util.disable(ok_btn, cancel_btn);
				ok_btn.text('操作正在进行...');
				this.options.confirm($.proxy(function(success) {
					ok_btn.text(this.options.text);
					$.util.enable(ok_btn, cancel_btn);
				}, this));
			}, this));
		},
		_tip: null,
		_destroy: function() { 
			this._tip.odTip('destroy');
		},

		show: function(e) {
			this._tip.odTip('show');
			e && e.stopPropagation();
		},
		hide: function(e) {
			this._tip.odTip('hide');
			e && e.stopPropagation();
		}
		
	}); //end of widget
	
})(jQuery);
