//=require 'jquery.crop'

function imagepreview(file, view, call) {

    var maxHeight = view.clientHeight,
        maxWidth = view.clientWidth,
        doc = document;
        
    function setsize(info, img){
        var iwidth, iheight;
        if((info.width / maxWidth) > (info.height / maxHeight)){
            iwidth =  maxWidth;
            iheight = Math.round(iwidth * info.height / info.width);
        } else {
            iheight = maxHeight;
            iwidth = Math.round(iheight * info.width / info.height);
        }
        with(view.style){
            height = iheight + "px";
            width = iwidth + "px";
            overflow = "hidden";
        }
        if(img){
            with(img.style){
                height = width = "100%";
            }
            view.innerHTML = "";
            view.appendChild(img);
        }

    }

    try{
        new FileReader();
        file.addEventListener("change", function(e){
            var image = this.files[0];
            function fireError(){
                var evObj = doc.createEvent('Events');
                evObj.initEvent( 'error', true, false );
                file.dispatchEvent(evObj);
                file.value = "";
            }
            if(!/^image\//.test(image.type)){
                e.stopPropagation();
                e.preventDefault();
                fireError();
                return false;
            }
            var reader = new FileReader(),
                img = new Image();
            reader.onerror = img.onerror = fireError;
            img.onload = function(){
                var info = {
                    height: img.height,
                    width: img.width,
                    name: image.name,
                    size: image.size
                };
                if( call(info) !== false ){
                    // console.log('setsize......');
                    setsize(info, img);
                }
                img.onload = img.onerror = null;
            }
            reader.onload = function (){
                img.src = reader.result;
            }
            reader.readAsDataURL(image);

        }, false);
    }catch(ex){
        
        file.attachEvent("onchange", function() {
            var path = file.value,
                tt = doc.createElement("tt"),
                name = path.slice(path.lastIndexOf("\\") + 1 );

            if("XMLHttpRequest" in window){
                file.select();
                path = doc.selection.createRange().text,
                doc.selection.empty();
            }

            function imgloader (mode){
                return "progid:DXImageTransform.Microsoft.AlphaImageLoader(src='" + path + "', sizingMethod='" + mode + "')";
            }
            (doc.body || doc.documentElement).appendChild(tt);
            with(tt.runtimeStyle){
                filter = imgloader("image");
                zoom = width = height = 1;
                position = "absolute";
                right = "9999em";
                top = "-9999em";
                border = 0;
            }
            var info = {
                height: tt.offsetHeight,
                width: tt.offsetWidth,
                name: name
            };
            if( info.height > 1 || info.width > 1 ){
                if(call(info) !== false ){
                    view.style.filter = imgloader("scale");
                    // console.log('setsize.22222222222.....');
                    setsize(info);
                }
            } else {
                file.fireEvent("onerror");
                event.cancelBubble = true;
                event.returnValue = false;
                this.value = "";
            }
            tt.parentNode.removeChild(tt);
        });
    }
    
}

jQuery(function($) {
    imagepreview(document.getElementById("file"), document.getElementById("preview"), function(info){
        // alert("文件名:" + info.name + "\r\n图片原始高度:" + info.height + "\r\n图片原始宽度:" + info.width);
        //这里若return false则不预览图片
        if (parseInt(info.width) < 104 || parseInt(info.height) < 104 || parseInt(info.size)/3000000 > 1){
            alert("上传的图片大小要小于2Mb，宽和高像素都要不小于104px!");
            return false;
        }       

        $("#preview").css({
            background: "none"
        });

        $("#preview").crop(function(e){
            $("input[type='hidden']").val([e.top, e.left, e.height, e.width].toString());
            var params = $($('.select-box')[1]).css(["width", "height", "left", "top"]);
            var rate1 = 36 / 104;
            // console.log(rate1 * parseInt(params.width));
            $($('.select-box')[2]).css({
                "width": rate1 * parseInt(params.width),
                "height": rate1 * parseInt(params.height),
                "left": rate1 * parseInt(params.left),
                "top": rate1 * parseInt(params.top),
            })
            var rate2 = 20 / 104;
            $($('.select-box')[3]).css({
                "width": rate2 * parseInt(params.width),
                "height": rate2 * parseInt(params.height),
                "left": rate2 * parseInt(params.left),
                "top": rate2 * parseInt(params.top),
            })
        }, ".thumb");
    });
    
    // The loading.gif will be a dead man in IE8 when i only use :
    // 
    // $('.avataria form').submit(function(){
    //     $('#loading-img').removeClass('dn');
    //     return true;
    // });
    // 
    var timer;
    function myTimer() {
        var sec = 120
        clearInterval(timer);
        timer = setInterval(function() { 
            sec--;
            // console.log('.......:'+sec+'............');
            if ($('iframe#avatar_return_iframe').contents().find('#retval input').val() == "true" || sec == -1) {
                clearInterval(timer);
                // console.log('.......Done!!!!............');
                window.location.replace('/users/setting/avatar')
            } 
        }, 1000);
    }
    $('.avataria form').submit(function(){
        $('<iframe id="avatar_return_iframe" name="avatar_return_iframe"></iframe>').addClass('dn').appendTo('.avataria');
        $(this).attr('target', 'avatar_return_iframe')
        $('#loading-img').removeClass('dn');
        // console.log('............loading............');
        myTimer();
        return true;
    });
});