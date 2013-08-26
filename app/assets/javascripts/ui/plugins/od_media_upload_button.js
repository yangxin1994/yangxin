//=require ../widgets/od_tip
//=require ../widgets/od_media_popup
//=require ../widgets/od_media_popuploader

(function( $ ) {

	$.widget("oopsdata.odMediaUploadButton", {
		options:{
			id:"",
			type:"I",
			value: {ids: [], links: []},
  			change: function(value) {},
  			_close:function(){},
  			getValue:function(value){}
		},

		_event:null,
		_create:function(){
			var _id=this.options.id;
			if(_id==""){
				_id=$.util.uid();
			}
			var _type=this.options.type;
			this.element.addClass("media-button-empty");
			this.element.bind("click", $.proxy(function(e){
				e.stopPropagation();
				var btn=$(e.target);
				var tipContent="tipContent"+_id;
				if($("#"+tipContent+" .tip"+_type+_id).length>0){
					
					$("#"+tipContent+" .tip"+_type+_id).odTip('show',true);
					
				}
				else if(this.options.value.ids.length!=0||this.options.value.links.length!=0){
					this.element.removeClass("media-button-empty").addClass("media-button-not-empty");
					$.od.odMediaPopup({
						id:_id,
						type:_type,
						value:this.options.value,
						btnClick:btn,
						container:tipContent,
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
						},this),
						setValue:$.proxy(function(value){
							this.options.value=value;
						},this)
					});
				}
				else{
					this.element.removeClass("media-button-not-empty").addClass("media-button-empty");
					$.od.odMediaPopuploader({type:_type,
						change:$.proxy(function(value){
							this.options.value = value;
							this.options.change(value);
						},this),
						callback:$.proxy(function(uploadvalue){
							this.options.value = uploadvalue;
							console.log("关闭odMediaPopuploader："+uploadvalue);
							this.checkEmpty(uploadvalue);
							//创建mediapopuploader,将选择的文件在页面tip内显示
							$.od.odMediaPopup({
								id:_id,
								type:_type,
								value:uploadvalue,
								btnClick:btn,
								container:tipContent,
								change:$.proxy(function(value){
									this.options.value = value;
									this.options.change(value);
								},this),
								callback:$.proxy(function(value){
									this.options.value = value;
									console.log("关闭odMediaPopup："+value);
									this.checkEmpty(value);
								},this),
								_close:$.proxy(function(){
									this.options._close();
								},this)
							});
						},this)
					});
				}
			}, this));
		},

		checkEmpty:function(uploadvalue){
			if(uploadvalue.ids.length!=0 || uploadvalue.links.length!=0)
				this.element.removeClass("media-button-empty").addClass("media-button-not-empty");
			else{
				this.element.removeClass("media-button-not-empty").addClass("media-button-empty");
				this.options._close();
			}
		},
		// Use the _setOption method to respond to changes to options
		_setOption: function( key, value ) {
			switch( key ) {
				case "value":
					// handle changes to clear option
					break;
			}
 
			$.Widget.prototype._setOption.apply( this, arguments );
		},

		// Use the destroy method to clean up any modifications your widget has made to the DOM
		destroy: function() {
			this.unbind();
			$.Widget.prototype.destroy.call(this);
		}
	});
}(jQuery))