//=require ./_base
//=require ./_templates/od_popup

/* ================================
 * The alert widget
 * ================================ */

(function($){
	
	$.odWidget('odPopup',{
		options:{
			type:'alert',//confirm,若为空则可自定义弹出框中内容
			title:'提示',
			withoutTitle: false,
			content:'你确定退出当前页面吗？',//object或字符串
			contentPosition:'center',//center,right
			popupStyle: null,
			closeButton:true,
			//default style:layer_main:230,110,20  
			size:{width:null, height:null, titleHeight:null},
			titleStyle:'be5', //black,be5标题栏的颜色
			verticalOffset:-50,//弹出框偏移程度
			horizontalOffset:0,
			overlayBackground:'#cdcdcd',//背景颜色
			overpayOpacity:0.3,//背景透明度
			overlayClick:false,
			draggable:false,//弹出框可拖拽，暂未实现
			okButton:{btnid:'btn_okid',btnclass:'btn_ok'},
			cancelButton:{btnid:'btn_cancelid',btnclass:'btn_cancel'},
			autoFocus: true,
			confirm: function(){ return false; },//false表示点击后关闭弹出框
			cancel: function(){ return false; },
			close: function(){}
		},

		_createEl:function(){
			if(!this.options.popupStyle) {
				this.options.popupStyle = window.config.application_name.toLowerCase();
			}
			if(this.options.callback) {
				console.warn('Callback in od_popup is deprecated, use confirm/cancle/close instead.');
				this.options.confirm = $.proxy(function() {
					return this.options.callback(true);
				}, this);
				this.options.cancel = $.proxy(function() {
					return this.options.callback(false);
				}, this);
			}
			this.element = this.hbs(this.options);
			this.setContent();
			this._show();
			this.newHeight();
		},

		setContent:function(){            
			if(_.isString(this.options.content)){
				var p=$("<p style='padding: 10px 0' />").addClass("f6");
				var w=this.options.size.width?this.options.size.width:230;
				p.css({
					"width":w-20+"px",
					"text-align":this.options.contentPosition
				});
				p.html(this.options.content)
			}
			else{//为jquery object
				var p = this.options.content;
			}
			this._find('.popup_content').append(p);
		},

		hide: function() {
			// console.log(this.options);
			this.options.close(true);
			this.destroy();
			this._overlay('hide');
		},
		_show: function() {            
			this._overlay('show');
			
			$("BODY").append(this.element);
			// IE6 Fix
			var pos = ($.browser.msie && parseInt($.browser.version) <= 6 ) ? 'absolute' : 'fixed'; 
			
			this.element.css({
				position: pos,
				zIndex: 99999,
				padding: 0,
				margin: 0
			});
			//set closeButton
			if(!this.options.closeButton){
				this._find('.close').hide();
			}

			if(this.options.withoutTitle){
				this._find('.popup_panel').hide();
			}
			//set width and height
			if(this.options.size.width){
				this._find('.layer_main').css({
					width:this.options.size.width+'px'
				});
				this._find('.layer_bg').css({
					width:this.options.size.width+10+'px'
				});
				this._find('.popup_panel').css({width:this.options.size.width-10+'px'});
			};
			if(this.options.size.height>=110){
				this._find('.layer_main').css({
					height:this.options.size.height+'px'
				});
				this._find('.layer_bg').css({
					height:this.options.size.height+10+'px'
				});
			}
			else if(this.options.size.height&&this.options.size.height<110){
				this._find('.popup_content').children().css("padding","0px");
				this._find('.popup_content').children().children().removeClass('mt10 ml10');
			};

			if(this.options.size.titleHeight){
				this._find('.popup_panel').css({height:this.options.size.titleHeight+'px'});
			}

			this._reposition();//弹出框定位

			if(this.options.type == 'alert')
				this.alertButton();
			else if(this.options.type == 'confirm'){//confirm
				this.confirmButton();
			}
			//set popupStyle
			if(this.options.popupStyle=="quillme"){
				this._find('.layer_main').removeClass("blackBorder").addClass("redBorder");
				this._find('.popup_panel').removeClass("blackBg").addClass("redBg");
				this._find('.popup_panel h1').removeClass("blackTxt").addClass("whiteTxt");
				this._find('.close').removeClass("btn_close2").addClass("btn_close3");
				this._find('.od-button').addClass("od-button-red");
			}
			else if(this.options.titleStyle == 'black'){
				this._find('.popup_panel').css('background','black');
				this._find('.popup_panel h1').css('color','white');
			}
			//右键点击关闭无效
			this._find('.close').on("contextmenu",function(){return false;});            

			this._find('.close').click($.proxy(function(e){
				e.stopPropagation();
				this.hide();
			},this));
			// Make draggable
			try {
				$(".layer_bg").draggable({
					handle:$('.popup_panel')
				});
				$(".popup_panel").css({ cursor: 'move' });
			} catch(e) {  }
		},

		_reposition: function() {
			var top = (($(window).height() / 2) - (this._find('.layer_bg').height() / 2)) + this.options.verticalOffset;
			var left = (($(window).width() / 2) - (this._find('.layer_bg').width() / 2)) + this.options.horizontalOffset;
			if( top < 0 ) top = 0;
			if( left < 0 ) left = 0;
			
			// IE6 fix
			if( $.browser.msie && parseInt($.browser.version) <= 6 ) top = top + $(window).scrollTop();
			
			this.element.css({
				top: top + 'px',
				left: left + 'px'
			});
			$("#popup_overlay").height($(document).height());
		},

		_overlay: function(status) {
			switch( status ) {
				case 'show':
					this._overlay('hide');
					$("BODY").append('<div id="popup_overlay"></div>');
					$("#popup_overlay").css({
						position: 'absolute',
						zIndex: 99998,
						top: '0px',
						left: '0px',
						width: '100%',
						height: $(document).height(),
						background:this.options.overlayBackground,
						opacity: this.options.overpayOpacity
					}).click($.proxy(function(e){
						if(this.options.overlayClick){
							this.hide();
						}
					},this));
				break;
				case 'hide':
					$("#popup_overlay").remove();
				break;
			}
		},

		alertButton:function(){
			var div=$('<div />');
			div.css({'text-align':'center','margin-top':'10px'});

			var btn =$('<button />').addClass('od-button').html('确 定');
			btn.attr('id',this.options.okButton.btnid);
			btn.addClass(this.options.okButton.btnclass);
			btn.appendTo(div);            
			this._find('.popup_content').append(div); 

			this._find('#'+this.options.okButton.btnid).click($.proxy(function(e){
				if(!this.options.confirm()) 
					this.hide();
			},this));

			this._find('#'+this.options.okButton.btnid).keypress($.proxy(function(e){
				if( e.keyCode == 13 || e.keyCode == 27 ) 
					this._find('#'+this.options.okButton.btnid).trigger('click');
			},this));
			if(this.options.autoFocus)
				this._find('#'+this.options.okButton.btnid).focus();
		},

		confirmButton:function(){
			var div=$('<div />');
			div.css({'text-align':'center','margin-top':'10px'});
			
			var btnO =$('<button />').addClass('od-button').html('确 定');
			btnO.attr('id',this.options.okButton.btnid);
			btnO.addClass(this.options.okButton.btnclass);

			var btnC =$('<button />').addClass('od-button').html('取 消');
			btnC.attr('id',this.options.cancelButton.btnid);
			btnC.addClass(this.options.cancelButton.btnclass);

			div.append(btnO).append(btnC);           
			this._find('.popup_content').append(div); 
			
			this._find('#'+this.options.okButton.btnid).click($.proxy(function(e){
				if(!this.options.confirm()) 
					this.hide();
			},this));
			this._find('#'+this.options.cancelButton.btnid).click($.proxy(function(e){
				if(!this.options.cancel()) 
					this.hide();
			},this));
			this._find('#'+this.options.okButton.btnid).keypress($.proxy(function(e) {
				if( e.keyCode == 13 || e.keyCode == 27 ) 
					this._find('#'+this.options.okButton.btnid).trigger('click');
			}, this));
			if(this.options.autoFocus)
				this._find('#'+this.options.okButton.btnid).focus();
		},

		newHeight:function(){
			var h = this._find('.layer_main').height()+10;
			this._find('.layer_bg').css('height',h);      
		},
	});
})(jQuery)