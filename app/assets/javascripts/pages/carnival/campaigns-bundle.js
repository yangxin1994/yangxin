jQuery(function($) {
    (function() {
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
    })();

    //提交手机
    $('.save-btn').click(function() {
        var mobile = $.trim($('#save_mobile_ipt').val());
        if (mobile == '') return;
        $.postJSON('/carnival/campaigns/update', {
            mobile: mobile
        }, function(retval) {
            console.log(retval);
        });
    });

    (function() {
        //活动介绍
        var ad = $('#ad')[0];
        var drag = ad.children[0];
        var b = window.show_ad;
        var a = ad.offsetTop;
        var timer = null;
        drag.onclick = function() {
            clearInterval(timer);
            adSport();
        };
        ad.onclick = function() {
            clearInterval(timer);
            adSport();
        }
        var giftBtn = $('.gifts a');
        for (var i = 0; i < giftBtn.length; i++) {

            giftBtn[i].onclick = function(ev) {
                var oEvent = ev || event;
                oEvent.cancelBubble = true;
            }
        }

        function adSport() {
            if (b) {
                timer = setInterval(function() {
                    a -= 10;
                    if (a <= -ad.offsetHeight) {
                        clearInterval(timer);
                        a = -ad.offsetHeight;
                        b = false;
                    }
                    ad.style.top = a + 'px';
                }, 20)
            } else {
                timer = setInterval(function() {
                    a += 10;
                    if (a >= 0) {
                        clearInterval(timer);
                        a = 0;
                        b = true;
                    }
                    ad.style.top = a + 'px';
                }, 20)
            };
        };
    })();

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

    $("#lotteryBtn").rotate({
        bind: {
            click: function() {
                if (!$("#lotteryBtn").hasClass('disabled')) {
                    var otext_f = $('.draw_remain').text().split(',')[0];
                    var otext_l = $('.draw_remain').text().split(',')[1];
                    var num = parseInt(otext_l.match(/\d+/)[0]);

                    $('.draw_remain').text(otext_f + ',还剩' + (num - 1) + '次')
                    var lotteryBtn = $("#lotteryBtn");

                    $("#lotteryBtn").addClass('disabled');
                    //t_type = 1; //抽奖
                    //t_type = 2; //分享抽奖

                    if (parseInt(window.data.lot_status[1]) > 0) {
                        var t_type = 2;
                    } else {
                        var t_type = 1;
                    }

                    if (t_type) {
                        $.post('/carnival/users/draw_lottery', {
                            type: t_type
                        }, function(data) {
                            var title = '';
                            var content = '';

                            function setDisabled() {
                                if (window.data.lot_status[1] > 0) {
                                    if (window.data.share_lottery_num >= window.data.share_num) {
                                        lotteryBtn.addClass('disabled');
                                    } else {
                                        lotteryBtn.removeClass('disabled');
                                    }
                                } else {
                                    if (window.data.share_lottery_num >= window.data.share_num + 1) {
                                        lotteryBtn.addClass('disabled');
                                    } else {
                                        lotteryBtn.removeClass('disabled');
                                    }
                                }
                            }

                            var share = '<p class="share_d">邀请好友参加活动，成功邀请1人，可再抽奖1次</p><p class="so_share">\
                                <a id="SinaWeibo" class="sina"></a>\
                                <a id="TencentWeibo" class="tencent"></a>\
                                <a id="Renren" class="renren"></a>\
                                <a id="Douban" class="douban"></a>\
                                <a id="QQSpace" class="qzone"></a>\
                               </p><p class="share_d">点击参与以下问卷,获得更多积分:</p>';

                            if (data.success) {
                                if (t_typ == 1) {
                                    window.data.lot_status[1] = 1;
                                } else {
                                    window.data.share_lottery_num += 1;
                                }
                                setDisabled();

                                title = '恭喜您中奖了!'
                                content = '恭喜您抽中了' + data.value + '我们会在问卷审核通过后联系您!'

                                if (data.value == window.data.priz_1) {
                                    rotateFunc(1, 157, function() {
                                        showNotice(title, content, true, function() {
                                            $(share).insertBefore('a.submit');
                                        });
                                    });
                                } else if (data.value == window.data.priz_2) {
                                    rotateFunc(2, 247, function() {
                                        showNotice(title, content, true, function() {
                                            $(share).insertBefore('a.submit');
                                        });
                                    });
                                } else if (data.value == window.data.priz_3) {
                                    rotateFunc(3, 22, function() {
                                        showNotice(title, content, true, function() {
                                            $(share).insertBefore('a.submit');
                                        });
                                    });
                                }
                            } else {
                                var code;
                                if (typeof(data.value.error_code) == 'number') {
                                    code = parseInt(data.value.error_code, 10);
                                } else {
                                    code = data.value.error_code
                                }
                                switch (code) {
                                    case -1:
                                        title = '对不起,该用户不存在!';
                                        break;
                                    case -2:
                                        title = '请先点亮小太阳';
                                        content = '<a href="/s/' + window.data.background_survey + '">请先点亮小太阳</a>';
                                        break;
                                    case -3:
                                        if (t_type == 3) {
                                            title = '请回答完摩天轮关卡的所有答题';
                                        } else if (t_type == 0) {
                                            title = '请回答完跳楼机关卡的所有答题';
                                        } else if (t_type == 4) {
                                            title = '请回答完热气球关卡的所有答题';
                                        } else if (t_type == 1) {
                                            title = '请回答完热气球关卡的所有答题';
                                        }

                                        $('.carnival-popup .submit').text('马上完成')
                                        $('.carnival-popup .submit').die('click');
                                        $('.carnival-popup .submit').bind('click', function() {
                                            $('.ly-plate').hide();
                                            $.fancybox.close();
                                        })
                                        break;
                                    case -4:
                                        title = '对不起,您已经参与过抽奖,不能再次抽奖';
                                        $('.ly-plate').hide();
                                        break;
                                    case -5:
                                        if (t_type == 1) {
                                            window.data.lot_status[1] = 1;
                                        } else {
                                            window.data.share_lottery_num += 1;
                                        }

                                        setDisabled();

                                        title = '抱歉,您本次没有抽中!';

                                        if (lotteryBtn.hasClass('disabled')) {
                                            var reload = true;
                                        }

                                        var cb = function() {
                                            $(share).insertBefore('a.submit');
                                        }
                                        break;
                                    case -6:
                                        title = '对不起,该手机号已经参与活动并领奖，不能重复参与!'
                                        if (lotteryBtn.hasClass('disabled')) {
                                            var reload = true;
                                        }
                                        break;
                                    case -7:
                                        title = '您已经成功抽取了' + window.data.prize_name + ',不能重复抽奖';
                                        if (lotteryBtn.hasClass('disabled')) {
                                            var reload = true;
                                        }
                                        break;
                                    default:
                                        break;
                                }
                                timeOut(function() {
                                    showNotice(title, content, reload, cb);
                                })
                            }
                        })
                    }
                }
            }
        }
    });


    var showNotice = function(title, content, reload, cb) {
        $.carnivalbox({
            width: 460,
            title: title,
            content: content,
            btnCont: '我知道了',
            beforeshow: function() {
                if (cb) {
                    cb();
                }
            },
            aftershow: function() {
                $('.carnival-popup a.btn').die('click');
                $('.carnival-popup a.btn').live('click', function() {
                    $.fancybox.close();
                    if (reload) {
                        window.location.reload();
                    } else {
                        if ($("#lotteryBtn").hasClass('disabled')) {
                            $('.ly-plate').hide();
                        }
                    }

                })
            }
        })
    }

    var timeOut = function(cb) { //超时函数
        var items = [67, 112, 202, 292, 337];
        var item = items[Math.floor(Math.random() * items.length)];
        var item = item + 2160;

        $("#lotteryBtn").rotate({
            angle: 0,
            duration: 10000,
            animateTo: item, //这里是设置请求超时后返回的角度，所以应该还是回到最原始的位置，2160是因为我要让它转6圈，就是360*6得来的
            callback: function() {
                cb();
            }
        });
    };

    var rotateFunc = function(awards, angle, cb) { //awards:奖项，angle:奖项对应的角度
        $('#lotteryBtn').stopRotate();
        $("#lotteryBtn").rotate({
            angle: 0,
            duration: 5000,
            animateTo: angle + 1440, //     angle是图片上各奖项对应的角度，1440是我要让指针旋转4圈。所以最后的结束的角度就是这样子^^
            callback: function() {
                cb();
            }
        });
    };



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


    function move(obj, json, sv, fnEnd) {
        //取CSS样式值
        function getStyle(obj, attr) {
            if (obj.currentStyle) {
                return obj.currentStyle[attr];
            } else {
                return getComputedStyle(obj, false)[attr];
            }
        }
        //运动开始      
        clearInterval(obj.timer);
        obj.timer = setInterval(function() {
            var isAllCompleted = true; //假设全部运动都完成了
            for (attr in json) {
                var attrValue = 0;
                switch (attr) {
                    case 'opacity':
                        attrValue = Math.round(parseFloat(getStyle(obj, attr)) * 100);
                        break;
                    default:
                        attrValue = parseInt(getStyle(obj, attr));
                }
                //如果没有传入sv，则为4
                var speed = (json[attr] - attrValue) / (sv || 4);
                speed = speed > 0 ? Math.ceil(speed) : Math.floor(speed);
                //如果循环过程中存在尚未结束的运动，isAllCompleted为假
                if (attrValue != json[attr]) isAllCompleted = false;
                switch (attr) {
                    case 'opacity':
                        {
                            obj.style.filter = "alpha(opacity=" + (attrValue + speed) + ")";
                            obj.style.opacity = (attrValue + speed) / 100;
                        };
                        break;
                    default:
                        obj.style[attr] = attrValue + speed + 'px';
                }
            } //for in end!
            //所有循环结束后，只有当全部运动结束后（isAllCompleted=true）时才关闭定时器
            if (isAllCompleted) {
                clearInterval(obj.timer);
                if (fnEnd) fnEnd();
            }
        }, 30);
    } //move() end !



});