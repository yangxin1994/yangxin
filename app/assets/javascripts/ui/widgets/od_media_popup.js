//=require ./_base
//=require ./_templates/od_media_popup
//=require ../../swfupload/swfupload-new.js
//=require ../../swfupload/handlers-new.js
//=require ../../swfupload/fileprogress-new
//=require jquery.cookie.js

/* ================================
 * The media popup widget
 * ================================ */

(function($){
	$.odWidget('odMediaPopup',{
		options:{
			id:"1",//只传数字即可
			type:"M",//I-image,V-vedio,M-music
			value:{
				ids:[],
				links:[]
			},
			corner:"50%",//箭头位置
			offset:{left:0,top:0},
			btnClick:null,
			container:"tipContent1",
			change:function(value){},
			_close:function(){},
			callback : function(material_ids_array) {}
		},
		chooseValue:{
			ids:[],
			links:[]
		},
		_createEl:function(){
			var content = this.hbs(this.options);

			if(this.options.value.ids.length!=0||this.options.value.links.length!=0){
				//创建mediatip,将选择的文件在页面tip内显示
				if($("#"+this.options.container).length<=0){
					var divC=$('<div />').appendTo('BODY');
					divC.attr("id",this.options.container);
				}
				else if($("#"+this.options.container+" .tip"+this.options.id).length>0){
					$("#"+this.options.container+" .tip"+this.options.id).remove();
				}
				var t= $.od.odTip({
					tipId:this.options.type+this.options.id,
					clickBtn:this.options.btnClick,
					appendto:"#"+this.options.container,
					tipCorner:this.options.corner,
					tipContent:content,
					tipWidth:240,
					title:false,
					hideCallback:this.options._close
				});
				this.element=t;
				this.getChooseValue(t);
				this.element.click(function(e){
					e.stopPropagation();
				});
				
				//重新选择
				this._find('.chooseAgain').click($.proxy(function(){
					this._hide();

					//创建media_popuploader
					$.od.odMediaPopuploader({
						type:this.options.type,
						value:this.options.value,
						callback: $.proxy(function(uploadvalue){
							//创建mediatip,将选择的文件在页面tip内显示
							this.options.change(uploadvalue);
							this.checkEmpty(uploadvalue);
							$.od.odMediaPopup({
								id:this.options.id,
								type:this.options.type,
								value:uploadvalue,
								btnClick:this.options.btnClick,
								container:this.options.container,
								callback:$.proxy(function(value){
									console.log("关闭odMediaPopup："+value);
									this.checkEmpty(value);
								},this),
								change:$.proxy(function(value){
									this.options.value = value;
									this.options.change(value);
								},this),
								_close:$.proxy(function(){
									this.options._close();
								},this)
							});
						},this)
					});
				},this)); 
				this._find('.btnOK').click($.proxy(function(){
					this._hide();
				},this));
				this.newHeight();
			}
			
		},
		//从数据库中获得此用户上传的该类文件
		getChooseValue:function(t){
			if(this.options.value.ids.length!=0){
				$.getJSON("/utility/materials.json",{material_type:this.transfer()},
					$.proxy(function(retval){
						if(retval.success) {
							console.log("success: get user upload file!");
							this.chooseValue={ids:[],links:[]};
							for(var i=0; i<this.options.value.ids.length; i++)
								for(var j=0; j<retval.value.length; j++)
									if(retval.value[j]._id==this.options.value.ids[i]){
										this.chooseValue.ids[i]=retval.value[j];
										break;
									}
							for(var i=0; i<this.options.value.links.length; i++)
								this.chooseValue.links[i]=this.options.value.links[i];
							this.showPic();
							t.odTip("show",true);																		
						}else {
							console.log("error: can't get user upload file!");
						}
				},this));
			}else{
				for(var i=0; i<this.options.value.links.length; i++)
					this.chooseValue.links[i]=this.options.value.links[i]; 
				this.showPic(); 
				t.odTip("show",true);
			} 
		},
		showPic:function(){
			if(this.options.type=="M"){
				for(var i=0;i<this.chooseValue.ids.length;i++){
					var div=$('<div />').addClass('picShow music_show');
					div.data("pic",i);
					var del='<div class="del-video-btn"></div>';		
					var imgpreview='<img class="img_upload music_upload" src="/assets/widgets/little-music.png"/>';
					var span='<span class="pl5">'+this.subStr(this.chooseValue.ids[i].title,15,div,3)+'</span>';
					div.html(del+imgpreview+span);
					this._find('.uploadBox').append(div);
				}
				for(var j=0;j<this.chooseValue.links.length;j++){
					var div=$('<div />').addClass('picShow music_show');
						div.data("lpic",j);
						var del='<div class="del-video-btn"></div>';	
						var imgpreview='<img class="img_upload music_upload" src="/assets/widgets/little-music.png"/>';
						var span='<span class="pl5">链接音频'+(j+1)+'</span>';
						div.html(del+imgpreview+span);
						this._find('.uploadBox').append(div);
				}
			}
			else{
				for(var i=0;i<this.chooseValue.ids.length;i++){
					var div=$('<div />').addClass('picShow');
					div.data("pic",i);
					var del='<div class="del-video-btn"></div>';		
					var imgpreview='<div class="img_preview"><img class="img_upload" src="/utility/materials/'+
						this.chooseValue.ids[i]._id+'/preview"/></div>';
					var span='<span>'+this.subStr(this.chooseValue.ids[i].title,15,div,3)+'</span>';
					div.html(del+imgpreview+span);
					this._find('.uploadBox').append(div);
				}
				for(var j=0;j<this.chooseValue.links.length;j++){
					var div=$('<div />').addClass('picShow');
						div.data("lpic",j);
						var del='<div class="del-video-btn"></div>';	
						var imgpreview='<div class="img_preview"><img class="img_upload" src="'
						+this.chooseValue.links[j]+'"/></div>';
						div.html(del+imgpreview);
						this._find('.uploadBox').append(div);
				}
			}
			this._find('.picShow').hover(function(){
				$(this).find('.del-video-btn').addClass('video-pic-hover');
			},function(){
				$(this).find('.del-video-btn').removeClass('video-pic-hover');
			});
			//点击删除
			this._find('.del-video-btn').bind("click",$.proxy(function(e){
				e.stopPropagation();

				if($(e.target).parent().data("lpic")!=null){//删除链接上传的文件
					var i = $(e.target).parent().data("lpic");
					this.delOneData(this.chooseValue.links,i);					
				}
				else{
					var i = $(e.target).parent().data("pic");
					this.delOneData(this.chooseValue.ids,i);			
				}

				$(e.target).parent().remove();
				if($("#"+this.options.container+" .tiptitle"+this.options.type+i).length>0) 
					$("#"+this.options.container+" .tiptitle"+this.options.type+i).remove();
				if($("#"+this.options.container).html=="")
					$("#"+this.options.container).remove();
				this.newHeight();
				console.log("delete choosefile in od_media_popup");
				this.options.change(this.getTempValueId());

				if(this.chooseValue.ids.length==0 && this.chooseValue.links.length==0){
					this._hide();
				}
			},this));
			//显示完整标题
			this._find('.substr').hover($.proxy(function(e){
				e.stopPropagation();
				var i = $(e.target).data("pic");
				$("#"+this.options.container+" .tiptitle"+this.options.type+i).odTip('show');
			},this),$.proxy(function(e){
				var i = $(e.target).data("pic"); 
				$("#"+this.options.container+" .tiptitle"+this.options.type+i).odTip('hide');
			},this));
			this.newHeight();
		},
		checkEmpty:function(uploadvalue){
			if(uploadvalue.ids.length!=0 || uploadvalue.links.length!=0)
				this.element.removeClass("media-button-empty").addClass("media-button-not-empty");
			else{
				this.element.removeClass("media-button-not-empty").addClass("media-button-empty");
				this.options._close();
			}
		},
		_hide:function(){
			this.destroy();
			for(var i=0; i<this.options.value.ids.length; i++)
				if($("#"+this.options.container+" .tiptitle"+this.options.type+i).length>0)
					$("#"+this.options.container+" .tiptitle"+this.options.type+i).remove();

			this.options.value={ids:[],links:[]};
			for(var i=0; i<this.chooseValue.ids.length; i++){
				this.options.value.ids[i]=this.chooseValue.ids[i]._id;
			}
			for(var i=0; i<this.chooseValue.links.length; i++){
				this.options.value.links[i]=this.chooseValue.links[i];
			}
			this.options.callback(this.options.value);
		},

		newHeight:function(){
			var h = this._find('.layer_main').height()+10;//汉波红枣
			this._find('.layer_bg').css('height',h);
		},
		subStr: function(str,l,content,top){
			if(str.length <= l)
				return str;
			else{
				content.addClass("substr");
				var i = content.data("pic");
				if($('.tiptitle'+this.options.type+i).length<=0){           	
					var showTitle = '<div class="long_title">'+str+'</div>';
					$.od.odTip({
						tipId:'title'+this.options.type+i,//class="tiptitleV1"
						title:false,
						tipTop:top,
						tipWidth:200,
						tipCorner:"2%",
						clickBtn:content,
						appendto:"#"+this.options.container,
						tipContent:showTitle,
						tipZIndex:100
					});
					return str.substring(0,l)+'...';
				}
			}
		},
		delOneData:function(data, delIndex){
			for(var i=delIndex; i<data.length-1; i++ ){
				data[i]=data[i+1];
			}
			data.length--;
		},
		setLocalC:function(){
			if(this.options.type == "I"){
				return '图片';
			}
			else if(this.options.type == "M"){
				return '音频';
			}
			else{
				return '视频';
			}
		},
		transfer:function(){//转换成数据库存储的内容
			if(this.options.type == "I"){
				this.options.title="图片";
				return 1;
			}
			else if(this.options.type == "M"){
				this.options.title="音频";
				return 2;
			}
			else{
				this.options.title="视频";
				return 4;
			}
		},
		getTempValueId:function(){
			var tempChooseValue={ids:[],links:[]};
			for(var i=0; i<this.chooseValue.ids.length; i++)
				tempChooseValue.ids[i]=this.chooseValue.ids[i]._id;
			tempChooseValue.links=this.chooseValue.links;
			console.log(tempChooseValue);
			return tempChooseValue;
		}

	});
})(jQuery)
