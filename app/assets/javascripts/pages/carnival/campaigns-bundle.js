//= require 'jquery.fancybox.pack'
jQuery(function($) {
    (function() {
        //顶部下拉菜单
        function pullDown(obj) {
            var oBox = $(obj)[0];
            oBox.onmouseover = function() {
                this.children[1].style.display = 'block';
                this.children[0].className = 'link active';
            };
            oBox.onmouseout = function() {
                this.children[1].style.display = 'none';
                this.children[0].className = 'link';
            };
        };
        pullDown('.questions');
        pullDown('.share');
        pullDown('.save');
    })();
    //收藏夹
    BookmarkApp = function() {
        var isIEmac = false; /*@cc_on @if(@_jscript&&!(@_win32||@_win16)&&(@_jscript_version<5.5)) isIEmac=true; @end @*/
        var isMSIE = (-[1, ]) ? false : true;
        var cjTitle = document.title; // Bookmark title 
        var cjHref = location.href; // Bookmark url

        function hotKeys() {
            var ua = navigator.userAgent.toLowerCase();
            var str = '';
            var isWebkit = (ua.indexOf('webkit') != -1);
            var isMac = (ua.indexOf('mac') != -1);

            if (ua.indexOf('konqueror') != -1) {
                str = 'CTRL + B'; // Konqueror
            } else if (window.home || isWebkit || isIEmac || isMac) {
                str = (isMac ? 'Command/Cmd' : 'CTRL') + ' + D'; // Netscape, Safari, iCab, IE5/Mac
            }
            return ((str) ? '请按' + str + ' 保存到收藏夹.' : str);
        }

        function isIE8() {
            var rv = -1;
            if (navigator.appName == 'Microsoft Internet Explorer') {
                var ua = navigator.userAgent;
                var re = new RegExp("MSIE ([0-9]{1,}[\.0-9]{0,})");
                if (re.exec(ua) != null) {
                    rv = parseFloat(RegExp.$1);
                }
            }
            if (rv > -1) {
                if (rv >= 8.0) {
                    return true;
                }
            }
            return false;
        }

        function addBookmark(a) {
            try {
                if (typeof a == "object" && a.tagName.toLowerCase() == "a") {
                    a.style.cursor = 'pointer';
                    if ((typeof window.sidebar == "object") && (typeof window.sidebar.addPanel == "function")) {
                        window.sidebar.addPanel(cjTitle, cjHref, ""); // Gecko
                        return false;
                    } else if (isMSIE && typeof window.external == "object") {
                        if (isIE8()) {
                            window.external.AddToFavoritesBar(cjHref, cjTitle); // IE 8                    
                        } else {
                            window.external.AddFavorite(cjHref, cjTitle); // IE <=7
                        }
                        return false;
                    } else if (window.opera) {
                        a.href = cjHref;
                        a.title = cjTitle;
                        a.rel = 'sidebar'; // Opera 7+
                        return true;
                    } else {
                        alert(hotKeys());
                    }
                } else {
                    throw "Error occured.\r\nNote, only A tagname is allowed!";
                }
            } catch (err) {
                alert(err);
            }
        }

        return {
            addBookmark: addBookmark
        }
    }();


    $.fancybox.open($('.reward_list'),{
      padding:0,
      autoSize:true,
      scrolling:"no",
      openEffect:'none',
      closeEffect:'none',        
      helpers : {
        overlay : {
          locked: false,
          closeClick: false,
          css : {
            'background' : 'rgba(51, 51, 51, 0.2)'
          }
        }
      }
    })


});