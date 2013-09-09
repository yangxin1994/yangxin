//=require ./_base
//=require ./_templates/od_tip

/* ================================
 * The practise widget
 * ================================ */

(function($){
	$.odWidget('odTip',{
		options:{
			tipId:'1',
			title:true,//是否显示title
			tipContent:"content",
			contentPlace:'left',//'right','center'
			clickBtn:null,//点击的button
			appendto:"BODY",//可传入class或id
			tipLeft:-4,//与点击按钮左侧偏移位置
			tipTop:7,
			tipWidth:null,
			tipCorner:"50%",//箭头的位置，默认在中间
			tipZIndex:99,
			hideCallback:function(){}
		},

		_createEl:function(){
			this.element = this.hbs(this.options);
			$(this.options.appendto).append(this.element);

			this.element.addClass("tip"+this.options.tipId);
			var w=240;
			if(_.isString(this.options.tipContent)){
				var p=$("<div />").css({
					"text-align":this.options.contentPlace,
					"padding":3+"px"
				});
				p.html(this.options.tipContent);
				this._find('.layer_main').append(p);
			}
			else{
				this._find('.layer_main').append(this.options.tipContent);
				w=this.options.tipContent.width();
			}

			if(this.options.tipWidth){
				this._find('.layer_bg').css("width",this.options.tipWidth+"px");
				this._find('.layer_main').css("width",(this.options.tipWidth-10) +"px");
			}
			else{
				this._find('.layer_bg').css("width",(w+10)+"px");
				this._find('.layer_main').css("width",w +"px");
			}

			this._find('.corner2').css("left",this.options.tipCorner);
			this.element.css({"z-index":this.options.tipZIndex}).hide();

			this._close = this._find('.btn_close2');
			if(!this.options.title){//如果不显示title
				this._close.hide();
			}

			this._close.on("contextmenu",function(){return false;});            

			this._close.mousedown($.proxy(function(e){
				e.stopPropagation();
				this.hide();
			},this));

		},

		_close: null,

		show:function(hideOther,tempClickBtn){

			if(this.options.clickBtn==null)
				this.options.clickBtn=tempClickBtn;

			if(hideOther)
				$(".od-tip").hide();
			var left = this.options.clickBtn.offset().left;
			var top = this.options.clickBtn.offset().top;
			var width=this.options.clickBtn.width();
			var height=this.options.clickBtn.height();

			var tipWidth=this._find('.layer_bg').width();
			var cornerPlace=tipWidth*parseInt(this.options.tipCorner)/100;
			
			var Top = top+height+this.options.tipTop+"px";
			var Left = left-cornerPlace+width/2+this.options.tipLeft+"px";
			this.element.css({"top":Top,"left":Left,"position":"absolute"}).show();

			this.element.click(function(e){
				e.stopPropagation();
			});
				
			$(document).one("click",$.proxy(function(){				
				this.hide();			
			},this));


			var h = this._find('.layer_main').height()+10;
			this._find('.layer_bg').css('height',h);  
			var w = this._find('.layer_main').width()+10;
			this._find('.layer_bg').css('width',w);
		},

		hideEl:function(){
			console.warn('method "hideEl" is deprecated. Please use "hide" instead.');
			this.hide();
		},

		hide: function() {
			this.element.hide();
			this.options.hideCallback();
		}
	});

})(jQuery);