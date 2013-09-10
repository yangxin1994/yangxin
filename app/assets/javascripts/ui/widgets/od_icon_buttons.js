//=require ./_base
//=require ./_templates/od_icon_buttons
//=require twitter/bootstrap/tooltip
 
/* ================================
 * The IconButtons widget
 * ================================ */

(function($) {
	
	$.odWidget('odIconButtons', {
		
		/* The default setting for plugin
		 * buttons:	[{
		 *	name: 'edit',
		 *	info: 'edit button',
		 *	click: function() {
		 *		alert(1);
		 *	}
		 * }]
		 * ================================ */
		options: {
			buttons: [],
			toggle: false
		},
		
		/* Set up the widget
		 * ================================ */
		_createEl: function() {
			this.element = this.hbs(this.options);
			
			if(this.options.buttons.length > 1) {
				this._find('.icon-btn:eq(0)').addClass('icon-btn-l');
				this._find('.icon-btn:eq(' + (this.options.buttons.length - 1) + ')').addClass('icon-btn-r');
			} else if(this.options.buttons.length == 1) {
				this._find('.icon-btn').addClass('icon-btn-single');
			}
			
			$.each(this.options.buttons, $.proxy(function(i, btn) {
				var $widget = this;
				var $btn = $widget._getBtn(i);
				
				// tooltip
				$btn.tooltip({
					placement: 'bottom',
					// delay: {show: 500, hide: 0}	
					// DO NOT delay. Bug happens when the widget is destroyed before the tooltip shows
				});
				
				$btn.hover(function() {
					$('.icon', $btn).addClass(btn.name + '_active');
				}, function() {
					$('.icon', $btn).removeClass(btn.name + '_active');
				});
				
				$btn.click(function(e) {
					if($widget._activeIndex == i)
						return;
					if(btn.click)
						btn.click(e);
				});
				
				if(this.options.toggle) {
					$btn.click(function() {
						if($widget._activeIndex == i)
							return;
						
						var $current_btn = $widget._activeBtn();
						if($current_btn && $current_btn.length > 0) {
							$current_btn.removeClass('active');
							$('.icon', $current_btn).removeClass(
								$widget.options.buttons[$widget._activeIndex].name + '-active');
						}
						
						$btn.addClass('active');
						$('.icon', $btn).addClass(btn.name + '-active');
						$widget._activeIndex = i;
					});
				}
				
			}, this));
			
		},
		
		_activeIndex: -1,
		_activeBtn: function() {
			if(this._activeIndex < 0) return null;
			return this._getBtn(this._activeIndex);
		},
		
		_getBtn: function(index) {
			return this._find('.icon-btn button:eq(' + index + ')');
		},
		
		trigger: function(index) {
			this._getBtn(index).trigger('click');
		},

		_destroy: function() { 
			$.each(this.options.buttons, $.proxy(function(i, btn) {
				this._getBtn(i).tooltip('destroy');
			}, this));
		},
		
	});
	
})(jQuery);
