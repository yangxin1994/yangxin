//=require ./_base
//=require ./_templates/od_autotip

(function($){
	$.odWidget('odAutotip',{
		options:{
			content:null,
			style:'info',//error
			place:'center', //left,center,right
			stayTime:8000,
			disappearTime:2000
		},

		_div:null,
		_tip:null,

		_createEl:function(){
			if($('body').find('.od-autotip').length<=0){
				this._div = $('<div />');
				this._div.addClass('od-autotip');
				$('body').append(this._div);
			}
			else{
				this._div = $('body').find('.od-autotip');
			}

			this._tip = this.hbs(this.options);
			this.element = this._div.append(this._tip);
			this.position();
			this.keepWidth();
			this.active();

			this._tip.find('.close-tip').click($.proxy(function(e){
				this.removeTip();
			},this));
		},

		position:function(){
			var top = this.element.position().top;
			var thiselement = this.element;
			var scrolls = $(window).scrollTop();
			var horizontal = 0;
			var vertical = 0;
			if (scrolls > top) {
				vertical = scrolls;
			}else {
				vertical = top;   
			}

			switch(this.options.place){
				case 'left': horizontal = 100;break;
				case 'center':horizontal=$(window).width()/2-this.element.width()/2;break;
				case 'right':horizontal = $('.od-container').width() +200; break;
			}
			thiselement.css({
				position: "absolute",
				top: vertical+'px',
				left:horizontal + 'px'
			});
			//浏览器滚动时仍显示在最上方
			$(window).scroll(function() {
				if(thiselement.html()!=""){ 
					var scrolls = $(this).scrollTop();
					if (scrolls > top) {
						if (window.XMLHttpRequest) {
							thiselement.css({
								position: "fixed",
								top: 0
							});
						}else{
							thiselement.css({
								top: scrolls
							});
						}
					}else{
						thiselement.css({
							position: "absolute",
							top: top
						});
					}
				}
			});
		},
		keepWidth:function(){
			var width =  this._tip.width();
			this._tip.css('width',width);
		},
		active:function(){
			setTimeout($.proxy(function () {
				this._tip.fadeTo(this.options.disappearTime,0.3,$.proxy(function(){
					this.removeTip();
				},this));
			},this), this.options.stayTime);
		},

		removeTip:function(){
			this._tip.remove();
			if(this.element.children().length<=0){
				this.destroy();
			}
		}
	});
})(jQuery)