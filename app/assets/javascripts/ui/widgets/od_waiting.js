//=require ./_base
//=require ./_templates/od_waiting

/* ================================
 * The widget od_waiting
 * ================================ */

(function($){
	$.odWidget('odWaiting',{
		options:{
			type: 2,//1代表居中大圈，2为可带文字
			message: '操作进行中',
			contentId:'',
			backColor:'white',
			addWidth:0,
			addHeight:0,
			onWaiting:function(){},
			onClose:function(){}
		},
		_createEl:function(){
			this.element = this.hbs(this.options);
			$(this.options.contentId).parent().append(this.element);
			
			
			var cHeight = $(this.options.contentId).outerHeight(true);
			var cWidth = $(this.options.contentId).outerWidth(true);
			var topC = $(this.options.contentId).position().top;
			var leftC = $(this.options.contentId).position().left;

			this.createWaiting(cHeight, cWidth);
			
			this.element.css({
				background:this.options.backColor,
				'height':cHeight+this.options.addHeight,
				'width':cWidth+this.options.addWidth,
				'top':topC,
				'left':leftC,
				'z-index':99999
			}).hide();
			
		},
		createWaiting:function(cHeight,cWidth){
			if(this.options.type==1){
				var img=$('<img />').addClass("wait-img");
				img.attr("src","../../assets/widgets/waiting.gif");
				this.element.append(img);

				var imgWidth = cHeight<cWidth ? cHeight/2 : cWidth/2;
				img.css({
					'width':imgWidth,
					'margin-left':'-'+imgWidth/2+'px',
					'margin-top':'-'+imgWidth/2+'px'
				});

			}else{//type=2
				var div=$("<div />").addClass('mark-waiting');
				var img=$('<img />').addClass('small-wait-img');
				img.attr("src","../../assets/widgets/load-white.gif");
				var span=$("<span />").html(this.options.message);
				div.append(img).append(span);
				this.element.append(div);

				/*var divWidth=div.outerWidth(true);
				div.css({'margin-left':'-'+divWidth/2+'px'});*/

			}
		},
		open:function(){

			this.element.show();
			if(this.options.type==2&&!this._find(".mark-waiting").hasClass("change-position")){

				this._find(".mark-waiting").addClass("change-position");
				var divWidth=this._find(".mark-waiting").outerWidth(true);
				this._find(".mark-waiting").css({
					'margin-left':'-'+divWidth/2+'px',
					'left':50+'%'
				});
			}
			if(this.options.onWaiting())
				this.options.onWaiting();
			return true;
		},
		close:function(){
			this.element.hide();
			if(this.options.onClose())
				this.options.onClose();
			return false;
		},
		waitDestroy:function(){
			this.destroy();
		}
	});
})(jQuery)