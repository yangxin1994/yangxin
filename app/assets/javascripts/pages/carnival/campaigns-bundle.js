jQuery(function($) {
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
    //滚动公告
    var oDiv = $('.bulletin')[0];
    var oUl = oDiv.children[0];
    oUl.innerHTML += oUl.innerHTML;
    var timer = null;
    run();

    function run() {
        clearInterval(timer);
        timer = setInterval(function() {
            if (oUl.offsetTop <= -oUl.offsetHeight / 2) {
                oUl.style.top = 0;
            };
            oUl.style.top = oUl.offsetTop - 1 + 'px';
            if (oUl.offsetTop % 40) {} else {
                clearInterval(timer);
                setTimeout(run, 5000);
            };
        }, 30);
    };
		//小太阳跟随滚动
		var sun = $('#sun')[0];
		window.onscroll = function(){
			
		}

    var timeOut = function() { //超时函数
        $("#lotteryBtn").rotate({
            angle: 0,
            duration: 10000,
            animateTo: 2160, //这里是设置请求超时后返回的角度，所以应该还是回到最原始的位置，2160      是因为我要让它转6圈，就是360*6得来的
            callback: function() {
                alert('网络超时')
            }
        });
    };

    var rotateFunc = function(awards, angle, text) { //awards:奖项，angle:奖项对应的角度
        $('#lotteryBtn').stopRotate();
        $("#lotteryBtn").rotate({
            angle: 0,
            duration: 5000,
            animateTo: angle + 1440, //     angle是图片上各奖项对应的角度，1440是我要让指针旋转4圈。所以最后的结束的角度就是这样子^^
            callback: function() {
                alert(text)
            }
        });
    };

    $("#lotteryBtn").rotate({
        bind: {
            click: function() {
                var time = [0, 1];
                time = time[Math.floor(Math.random() * time.length)];
                if (time == 0) {
                    timeOut(); //网络超时
                }
                if (time == 1) {
                    var data = [1, 2, 3, 0]; //返回的数组
                    data = data[Math.floor(Math.random() * data.length)];
                    if (data == 1) {
                        rotateFunc(1, 157, '恭喜您抽中的一等奖')
                    }
                    if (data == 2) {
                        rotateFunc(2, 247, '恭喜您抽中的二等奖')
                    }
                    if (data == 3) {
                        rotateFunc(3, 22, '恭喜您抽中的三等奖')
                    }
                    if (data == 0) {
                        var angle = [67, 112, 202, 292, 337];
                        angle = angle[Math.floor(Math.random() * angle.length)]
                        rotateFunc(0, angle, '很遗憾，这次您未抽中奖')
                    }
                }
            }
        }

    });



//收藏夹
BookmarkApp = function () {
  var isIEmac = false; /*@cc_on @if(@_jscript&&!(@_win32||@_win16)&&(@_jscript_version<5.5)) isIEmac=true; @end @*/
  var isMSIE = (-[1,]) ? false : true;
  var cjTitle = document.title; // Bookmark title 
  var cjHref = location.href;   // Bookmark url

  function hotKeys() {
    var ua = navigator.userAgent.toLowerCase();
    var str = '';
    var isWebkit = (ua.indexOf('webkit') != - 1);
    var isMac = (ua.indexOf('mac') != - 1);

    if (ua.indexOf('konqueror') != - 1) {
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
    if (rv > - 1) {
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
    addBookmark : addBookmark
  }
}();





});