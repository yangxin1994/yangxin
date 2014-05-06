//=require ./_base
//=require ./od_popup
//=require ../plugins/od_enter
//=require ./_templates/od_media_popuploader
//=require ../../swfupload/swfupload-new.js
//=require ../../swfupload/handlers-new.js
//=require ../../swfupload/fileprogress-new
//=require jquery.cookie.js

/* ================================
 * The Media Popuploader widget
 * ================================ */

(function($) {
    var fileInfo = {
        I: [],
        M: [],
        V: []
    };
    $.odWidget('odMediaPopuploader', {
        options: {
            type: 'V',
            value: {
                ids: [],
                links: []
            },
            title: "视频",
            callback: function(value) {},
            change: function(value) {},
            setValue: function(value) {},
            verticalOffset: 0,
            horizontalOffset: 0,
            overlayBackground: '#cdcdcd',
            overpayOpacity: 0.3,
            zIndex: 999
        },
        pageInfo: {
            totalFile: 0, //该用户该类文件总数
            currFile: 0, //当页显示文件数（<=7)
            currPage: 1, //当前显示页面
            totalPage: 1, //总共页面
            beforeFile: 0, //在此页之前一共有多少个文件
            beginId: 6 //此页第一个文件的id（倒排列）
        },
        fileData: [],
        chooseValue: {
            ids: [],
            links: []
        }, //index存储在页面的id号，data存储此数据

        _createEl: function() {
            if (this.checkLogin()) {
                this.element = this.hbs(this.options);
                this._show();
                this.getUserFile();
                this.uploadEvent();
                this.newHeight();
            }
        },
        uploadEvent: function() {
            //本地、链接切换
            this._find('.internetMedia').hide();
            this._find('.toggle').click($.proxy(function(e) {
                var btn = $(e.target).parentsUntil('.toggle').parent();
                if (!this.element.hasClass('uploading')) {
                    if (!btn.children().hasClass('active')) {
                        btn.children().addClass(('active'));
                    }
                    if (btn.hasClass('toggle-btn-y-l')) { //点击左侧按钮--本地
                        btn.parentsUntil('.layer_main').parent().find('.localMedia').show();
                        btn.parentsUntil('.layer_main').parent().find('.internetMedia').hide();
                        btn.next().children().removeClass('active');
                        this._find('.layer_bg').css('minHeight', '420px');
                        this._find('.layer_main').css('minHeight', '410px');
                    } else { //点击右侧链接按钮--链接
                        btn.parentsUntil('.layer_main').parent().find('.internetMedia').show();
                        btn.parentsUntil('.layer_main').parent().find('.localMedia').hide();
                        btn.prev().children().removeClass('active');
                        this._find('.layer_bg').css('minHeight', '160px');
                        this._find('.layer_main').css('minHeight', '150px');
                    }
                    this.newHeight();
                }
            }, this));

            //本地上传处的完成按钮
            this._find('.finish-btn').click($.proxy(function(e) {
                e.stopPropagation();
                this._hide();
                this.setValue();
                this.options.callback(this.options.value);
            }, this));

            //链接 确定按钮
            this._find(".internetMedia .link_address").odEnter({
                enter: function(e) {
                    this._find('.internetMedia .btn_linkOk').click();
                }
            });

            this._find(".internetMedia .link_address").keyup($.proxy(function(e) {
                e.stopPropagation();
                var link_btn = this._find('.internetMedia .btn_linkOk');
                if ($(e.target).val() == "") {
                    link_btn.removeClass("od-button-white");
                    link_btn.html("确定");
                } else {
                    link_btn.addClass("od-button-white");
                    link_btn.html("添加");
                }
            }, this));

            this._find('.internetMedia .btn_linkOk').click($.proxy(function(e) {
                e.stopPropagation();
                var btn = $(e.target);
                var linkNo = this.chooseValue.links.length;
                var linkUrl = btn.prev().val();
                if (linkUrl == "") {
                    this._hide();
                    this.setValue();
                    this.options.callback(this.options.value);
                } else {
                    this.createLinkFile(linkUrl, linkNo);
                    this.chooseValue.links[linkNo] = linkUrl;
                    this.delFile(false);
                    btn.removeClass("od-button-white");
                    btn.html("确定");
                    btn.prev().val("");
                    this.newHeight();

                    console.log("choose linkfile");
                    this.options.change(this.getTempValueId());
                }
            }, this));

            //关闭按钮
            this._find('.btn_close2').click($.proxy(function(e) {
                e.stopPropagation();
                this._hide();
                this.options.callback(this.options.value);
            }, this));

            //上传完成后调用
            this._find('.pagination .firstPage').bind('myclick', $.proxy(function(event, value) {
                console.log(value);
                this.removeVideo();
                this.fileData[this.pageInfo.totalFile] = value;
                this.showFile(this.pageInfo.totalFile + 1, 1, true);
                this._find('#video' + this.pageInfo.beginId + ' .tick-checkBtn').click();
            }, this));

            //分页按钮
            this._find('.pagination .pre').click($.proxy(function(e) {
                e.stopPropagation();
                if (this.pageInfo.currPage > 1) {
                    var no = this.pageInfo.currPage - 1;
                    this.removeVideo();
                    this.showFile(this.pageInfo.totalFile, no, false);
                    this.setPageButton('next', true);
                }
                if (this.pageInfo.currPage == 1) {
                    this.setPageButton('previous', false);
                }
            }, this));
            this._find('.pagination .nx').click($.proxy(function(e) {
                e.stopPropagation();
                if (this.pageInfo.currPage < this.pageInfo.totalPage) {
                    var no = this.pageInfo.currPage + 1;
                    this.removeVideo();
                    this.showFile(this.pageInfo.totalFile, no, false);
                    this.setPageButton('previous', true);
                }
                if (this.pageInfo.currPage == this.pageInfo.totalPage) {
                    this.setPageButton('next', false);
                }
            }, this));
        },
        //从数据库中获得此用户上传的该类文件
        getUserFile: function() {
            this.fileData = [];
            var w = $.od.odWaiting({
                contentId: '.localMedia',
                addHeight: 10
            });
            if (this.getFileInfo().length == 0) { //没有获得上传数据
                w.odWaiting('open');
                $.getJSON("/utility/materials.json", {
                        material_type: this.transfer()
                    },
                    $.proxy(function(retval) {
                        console.log(retval);
                        if (retval.success) {
                            console.log("success: get user upload file!");
                            for (var i = 0; i < retval.value.length; i++) { //请求数据按上传时间最早在前
                                this.fileData[i] = retval.value[i];
                            }
                            this.setFileInfo(this.fileData);
                            this.setChooseValue();
                            this.showFile(retval.value.length, 1, false);
                            w.odWaiting('close');
                            for (var i = 0; i < this.chooseValue.links.length; i++)
                                this.createLinkFile(this.chooseValue.links[i], i);
                        } else {
                            console.log("error: can't get user upload file!");
                            this.setPage(0, 1);
                            w.odWaiting('close');
                        }
                    }, this));
            } else {
                w.odWaiting('open');
                this.chooseAgain();
                w.odWaiting('close');
            }
        },
        //初始化时显示已上传的文件以供选择:num总共文件数
        showFile: function(num, cpage, afterupload, chooseAgain) {
            var i = 0;
            this.setPage(num, cpage);
            var p = this.pageInfo;
            if (afterupload) { //如果刚上传完成,显示第一页
                this.createFile(this.fileData[p.beginId], this._find('.localMedia .first-line'), p.beginId, false);
                i++;
            }
            for (; i < p.currFile; i++) {
                var thisId = p.beginId - i;
                if (i == 0 || i == 1 || i == 2)
                    this.createFile(this.fileData[thisId], this._find('.localMedia .first-line'), thisId, false);
                else if (i == 3) {
                    this.createFile(this.fileData[thisId], this._find('.localMedia .second-line'), thisId, true);
                } else { //4,5,6
                    this.createFile(this.fileData[thisId], this._find('.localMedia .second-line'), thisId, false);
                }
            }
            if (this.options.type == "M") {
                this._find(".video-pic").addClass("music-pic");
            }
            this.newHeight();
            this.chooseFile();
            this.arrangeTitle(chooseAgain);
            this.delFile();
        },
        //创建本地上传及数据库中的文件
        createFile: function(v, holder, i, first) {
            var div = $('<div />').addClass('video-show');
            div.attr("id", "video" + i);
            div.data("id", i);
            if (!first) div.addClass('ml10');

            var img = '<img src="/utility/materials/' + v._id + '/preview"/>';
            if (this.options.type == "M") {
                img = "";
            }
            var divPic = '<div class="video-pic"><div class="del-video-btn"></div>' + img + '</div>';
            var divNote = '<div class="video-note"><label><input type="checkbox" class="tick-checkBtn' +
                '"></input><span>' + this.subStr(v.title, 5) + '</span></label></div>';
            holder.append(div.html(divPic + divNote));
        },
        chooseFile: function() { //显示并记录已选择的文件,在showFile中调用
            this._find(".localMedia .video-pic").click($.proxy(function(e) {
                var i = $(e.target).parentsUntil('.video-show').parent().data("id");
                this._find('#video' + i + ' .tick-checkBtn').click();
            }, this));
            this._find('.localMedia .tick-checkBtn').click($.proxy(function(e) {
                var tick = $(e.target);

                e.stopPropagation();
                var i = tick.parent().parent().parent().data("id");
                var chooseId = this.chooseValue.ids.length;
                if (tick.hasClass('true')) { //点击后取消
                    tick.removeClass('true');
                    this.delOneData(this.chooseValue.ids, tick.data("chooseId"));

                    var titleDiv = this._find('.chosen-video .title-div');
                    titleDiv.find("#titleSpan" + i).next().remove();
                    titleDiv.find("#titleSpan" + i).remove();
                    this.newHeight();
                } else { //选中
                    tick.addClass('true');
                    tick.data("chooseId", chooseId);
                    this.chooseValue.ids[chooseId] = {
                        data: this.fileData[i],
                        dataId: i
                    };
                    var span = $('<span />').attr("id", "titleSpan" + i);
                    span.html(tick.next().html());
                    var dot = $('<span />').html("、");
                    this._find('.chosen-video .title-div').append(span).append(dot);
                    this.newHeight();
                }

                console.log("choose or cancel file");
                this.options.change(this.getTempValueId());
            }, this));
        },
        //链接的上传,确认后的显示在后面
        createLinkFile: function(link, i) {
            var lineNo = Math.floor(i / 4);

            var div = $('<div />').addClass('link-show');
            div.attr("id", "linkShow" + i);
            div.data("linkNo", i);
            if (i % 4 == 0) { //每行第一个
                var con = $('<div />').addClass("line" + lineNo);
                this._find(".link-container").append(con);
            } else {
                div.addClass('ml10');
            }
            var holder = this._find(".internetMedia .line" + lineNo);

            var img = '<img src="' + link + '"/>';
            var divPic = '<div class="video-pic"><div class="del-video-btn"></div>' + img + '</div>';
            if (this.options.type == "M") {
                divPic = '<div class="video-pic music-pic"><div class="del-video-btn"></div></div>';
            }
            holder.append(div.html(divPic));
        },
        //删除操作
        delFile: function(chooseAgain) {
            console.log("delFile");
            this._find('.localMedia .del-video-btn').click($.proxy(function(e) {
                e.stopPropagation();
                var i = $(e.target).parent().parent().data("id");
                delId = this.fileData[i]._id;
                $.deleteJSON("/utility/materials/" + delId + ".json", null, $.proxy(function(msg) {
                    if (msg) { //返回true
                        console.log("success:delete" + this.fileData[i].title);
                        for (var k = 0; k < this.chooseValue.ids.length; k++) { //如果删除被选中的视频
                            if (this.chooseValue.ids[k].dataId == i) {
                                this.delOneData(this.chooseValue.ids, k);

                                this._find('.chosen-video .title-div').find("#titleSpan" + i).next().remove();
                                this._find('.chosen-video .title-div').find("#titleSpan" + i).remove();

                                console.log("delete choosefile");

                                this.options.change(this.getTempValueId());
                                break;
                            }
                        }

                        this.changeDataId(i);
                        this.delOneData(this.fileData, i);
                        this.setFileInfo(this.fileData);
                        this.removeVideo();
                        var pageNo = this.pageInfo.currPage;
                        this.showFile(this.fileData.length, pageNo, false);
                        this.arrangeTitle();
                    } else {
                        console.log("error:delete");
                    }
                }, this));
            }, this));
            //链接中的删除按钮
            this._find('.internetMedia .del-video-btn').click($.proxy(function(e) {
                e.stopPropagation();
                var i = $(e.target).parent().parent().data("linkNo");
                if (i >= 0) {
                    this.delOneData(this.chooseValue.links, i);
                    this._find('.link-container').html('');
                    for (var t = 0; t < this.chooseValue.links.length; t++)
                        this.createLinkFile(this.chooseValue.links[t], t);

                    this.delFile(false);
                    this.newHeight();
                    console.log("delete chooselinkfile");
                    this.options.change(this.getTempValueId());
                }
            }, this));

            $('.od-uploadtip .video-pic').live({
                mouseenter: function() {
                    $(this).find('.del-video-btn').addClass('video-pic-hover');
                },
                mouseleave: function() {
                    $(this).find('.del-video-btn').removeClass('video-pic-hover');
                }
            });
        },
        removeVideo: function() {
            for (var i = 0; i < this.pageInfo.currFile; i++) {
                var thisId = this.pageInfo.beginId - i;
                this._find(".popup_show #video" + thisId).remove();
            }
        },
        //设置分页,在getUserFile中进行第一次设置
        setPage: function(num, cpage) {
            if (num > 0) {
                this.pageInfo.totalFile = num;
                this.pageInfo.currPage = cpage;
                this.pageInfo.totalPage = Math.ceil(num / 7);
                this.pageInfo.beforeFile = (cpage - 1) * 7;
                this.pageInfo.beginId = this.pageInfo.totalFile - this.pageInfo.beforeFile - 1;
                if (this.pageInfo.currPage == this.pageInfo.totalPage) {
                    this.pageInfo.currFile = this.pageInfo.totalFile - this.pageInfo.beforeFile;
                } else {
                    this.pageInfo.currFile = 7;
                }
            } else if (num == 0) {
                this.pageInfo.totalFile = 0;
                this.pageInfo.currFile = 0;
                this.pageInfo.currPage = 1;
                this.pageInfo.totalPage = 1;
                this.pageInfo.beforeFile = 0;
                this.pageInfo.beginId = 0;
            }
            this._find('.pagination .current').html(this.pageInfo.currPage);
            this._find('.pagination .total').html("/" + this.pageInfo.totalPage);
            if (this.pageInfo.currPage == 1) {
                this.setPageButton('previous', false);
            }
            if (this.pageInfo.currPage == this.pageInfo.totalPage) {
                this.setPageButton('next', false);
            }
        },
        setPageButton: function(pn, enable) {
            var str = "上一页";
            var str2 = "到底了";
            if (pn == "next") {
                str = "下一页";
                str2 = "到顶了";
            }
            if (enable) {
                this._find(".pagination .dis_" + pn).removeClass('dis_' + pn)
                    .addClass(pn).attr("title", str);
            } else {
                this._find('.pagination .' + pn).removeClass(pn)
                    .addClass('dis_' + pn).attr("title", str2);
            }
        },
        //点击重新选择按钮，调用showFile
        arrangeTitle: function(chooseAgain) {
            for (var i = 0; i < this.chooseValue.ids.length; i++) {
                //checkbox选中
                var did = this.chooseValue.ids[i].dataId;
                this._find('#video' + did + ' .tick-checkBtn').addClass('true').data("chooseId", i);
                this._find('#video' + did + ' .tick-checkBtn').attr("checked", "checked");
                //底部显示title
                if (chooseAgain) {
                    var span = $('<span />').attr("id", "titleSpan" + did);
                    span.html(this.subStr(this.chooseValue.ids[i].data.title, 5));
                    var dot = $('<span />').html("、");
                    this._find('.chosen-video .title-div').append(span).append(dot);
                }
            }
        },
        chooseAgain: function() { //在getUserFile中调用,当已经从数据库中获得此类数据
            this.fileData = this.getFileInfo();
            this.setChooseValue();
            for (var i = 0; i < this.chooseValue.links.length; i++)
                this.createLinkFile(this.chooseValue.links[i], i);
            this.showFile(this.fileData.length, 1, false, true);
        },
        //显示弹出框
        _show: function() {
            this._overlay('show');

            $("BODY").append(this.element);
            this.setLinkC();
            this.createUpload();
            //暂时隐藏
            if (this.options.type != "I") {
                var div = $('<div />').addClass("temp-title");
                div.html("上传" + this.options.title);
                this._find(".toggle-btn").replaceWith(div);
            }

            // IE6 Fix
            var pos = ($.browser.msie && parseInt($.browser.version) <= 6) ? 'absolute' : 'fixed';

            this.element.css({
                position: pos,
                zIndex: this.options.zIndex,
                padding: 0,
                margin: 0
            });
            this.element.css({
                minWidth: this.element.width(),
                maxWidth: this.element.width()
            });

            this._reposition();

            this._find('.btn_close2').on("contextmenu", function() {
                return false;
            });

            this.element.click(function(e) {
                e.stopPropagation();
            });
            $(document).click(function() {
                var cc = $('.od-uploadtip .progressWrapper .cancel');
                if (cc.hasClass('sure')) {
                    cc.removeClass('sure');
                    cc.html('取消');
                }
            });
        },
        _hide: function() {
            this.destroy();
            this.fileData = [];
            this._overlay('hide');
        },
        _reposition: function() {
            var top = (($(window).outerHeight() / 2) - (this.element.outerHeight() / 2)) + this.options.verticalOffset;
            var left = (($(window).width() / 2) - (this.element.width() / 2)) + this.options.horizontalOffset;
            if (top < 0) top = 0;
            if (left < 0) left = 0;

            // IE6 fix
            if ($.browser.msie && parseInt($.browser.version) <= 6) top = top + $(window).scrollTop();

            this.element.css({
                top: top + 'px',
                left: left + 'px'
            });
            $("#upload_overlay").height($(document).height());
        },
        _maintainPosition: function(status) {
            switch (status) {
                case true:
                    $(window).bind('resize', this._reposition);
                    break;
                case false:
                    $(window).unbind('resize', this._reposition);
                    break;
            }
        },
        _overlay: function(status) {
            switch (status) {
                case 'show':
                    this._overlay('hide');
                    $("BODY").append('<div id="upload_overlay"></div>');
                    $("#upload_overlay").css({
                        position: 'absolute',
                        zIndex: this.options.zIndex - 1,
                        top: '0px',
                        left: '0px',
                        width: '100%',
                        height: $(document).height(),
                        background: this.options.overlayBackground,
                        opacity: this.options.overpayOpacity
                    });
                    break;
                case 'hide':
                    $("#upload_overlay").remove();
                    break;
            }
        },
        // swfupload
        swfu: null,
        createUpload: function() {
            var type = this.options.type;
            var typeid = this.transfer();
            var key = "";
            if ($.cookie("auth_key")) //判断是否登录
                key = $.cookie("auth_key");
            else { //未登录
                this._find("#spanButtonPlaceHolder" + type).css("visibility", "hidden");
                this._find('.temp-button').css("display", "inline-block");
            }

            if (type == 'V') {
                var typeStr = "*.mp4;*.3gp;*,rmvb;*.avi;*.wmv";
                var description = "视频文件";
                var postparams = {};
                var postname = "Filedata";
            } else if (type == 'M') {
                var typeStr = "*.mp3;*.wma;*.amr";
                var description = "音频文件";
                var postparams = {};
                var postname = "Filedata";
                this.defaultPic = "/assets/widgets/music.png";
            } else {
                var typeStr = "*.jpg;*.png;*.jpeg;*.gif";
                var description = "图片文件";

                var postparams = {
                    material_value: "",
                    material_title: 111,
                    material_type: typeid,
                    auth_key: key
                };
                var postname = "image_src";
            }
            var settings = {
                flash_url: "/assets/swfupload/swfupload.swf",
                upload_url: "",

                post_params: postparams,
                file_post_name: postname,
                file_size_limit: "1000 MB",
                file_types: typeStr, //允许上传的文件类型
                file_types_description: "All Files", //文件类型描述
                file_upload_limit: 100, //限定用户一次性最多上传多少个文件，在上传过程中，该数字会累加，如果设置为“0”，则表示没有限制
                custom_settings: { //自定义设置
                    fileType: typeid,
                    progressTarget: "fsUploadProgress" + type,
                    uploadButton: "button" + type,
                    videoCode: "",
                    uploadOver: false,
                    defaultPic: this.defaultPic
                },
                button_image_url: "/assets/widgets/upload-add.png",
                button_width: "90",
                button_height: "90",
                button_placeholder_id: "spanButtonPlaceHolder" + type,

                //是否打开调试信息，默认为false
                //debug: true,
                file_dialog_start_handler: fileDialogStart, //当文件选取对话框弹出前出发的事件处理函数
                file_queued_handler: fileQueued,
                file_queue_error_handler: fileQueueError,
                file_dialog_complete_handler: fileDialogComplete,
                upload_start_handler: uploadStart, //开始上传文件前触发的事件处理函数
                upload_progress_handler: uploadProgress,
                upload_error_handler: uploadError,
                upload_success_handler: uploadSuccess, //文件上传成功后触发的事件处理函数
                upload_complete_handler: uploadComplete,
                queue_complete_handler: queueComplete // Queue plugin event}
            };

            this.swfu = new SWFUpload(settings);
            this._find('.temp-button').click($.proxy(function() {
                if ($(e.target).hasClass("temp-btn-uploading"))
                    alert('请上传完成后再点击上传！');
                else {
                    var login = $.od.odLogin({
                        callback: function() {
                            this._find("#spanButtonPlaceHolder" + type + id).css("visibility", "visible");
                            this._find('.temp-button').hide();
                        }
                    });
                }
            }, this));
        },
        //辅助函数
        newHeight: function() { //调整阴影高度
            var h = this._find('.layer_main').height() + 10;
            this._find('.layer_bg').css('height', h);
        },
        subStr: function(str, l) { //省略字符串
            if (str.length <= l)
                return str;
            else {
                return str.substring(0, l) + '...';
            }
        },
        setLinkC: function() { //设置链接的显示文字
            var link = null;
            if (this.options.type == "M") {
                link = '<p class="link_txt">目前已支持<a href="#">新浪乐库</a><em>、</em><a href="#">Songtaste</a><em>、</em>' +
                    '<a href="#">酷我音乐</a>的播放页面链接, 也支持MP3格式歌曲链接</p>';
            } else if (this.options.type == "V") {
                link = '<p class="link_txt">目前已支持<a href="#">新浪播客</a><em>、</em><a href="#">优酷网</a><em>、</em><a href="#">土豆网</a><em>、</em>' +
                    '<a href="#">酷6网</a><em>、</em><a href="#">我乐网</a><em>、</em><a href="#">奇异网</a><em>、</em><a href="#">凤凰网</a>等视频网站的播放页面链接</p>';
            }
            this._find('.internetMedia form').append(link);
        },
        transfer: function() { //转换成数据库存储的内容
            this.options.title = "图片";
            var typeid = 1;
            if (this.options.type == "M") {
                this.options.title = "音频";
                //typeid = 2
                typeid = 4
            } else if (this.options.type == "V") {
                this.options.title = "视频";
                //typeid = 4
                typeid = 2
            }
            this._find(".internetMedia .upload_type").html("链接" + this.options.title);
            this._find(".localMedia .add-font").html("点击添加新" + this.options.title);
            return typeid;
        },
        setFileInfo: function(value) {
            if (this.options.type == "I") {
                fileInfo.I = value;
            } else if (this.options.type == "M") {
                fileInfo.M = value;
            } else {
                fileInfo.V = value;
            }
        },
        getFileInfo: function() {
            if (this.options.type == 'I') {
                return fileInfo.I;
            } else if (this.options.type == 'M') {
                return fileInfo.M;
            } else if (this.options.type == 'V') {
                return fileInfo.V;
            }
        },
        checkLogin: function() { //判断是否登录
            if ($.cookie("auth_key"))
                return true;
            else {
                var login = $.od.odLogin();
                return false;
            }
        },
        delOneData: function(data, delIndex) { //删除data数组的一个数据
            for (var i = delIndex; i < data.length - 1; i++) {
                data[i] = data[i + 1];
            }
            data.length--;
        },
        changeDataId: function(delIndex) {
            for (var i = 0; i < this.chooseValue.ids.length; i++) {
                if (this.chooseValue.ids[i].dataId > delIndex)
                    this.chooseValue.ids[i].dataId--;
            }
        },
        setChooseValue: function() { //create时将value值赋给chooseValue
            this.chooseValue = {
                ids: [],
                links: []
            };
            for (var i = 0; i < this.options.value.ids.length; i++) {
                for (var j = 0; j < this.fileData.length; j++) {
                    if (this.options.value.ids[i] == this.fileData[j]._id) {
                        this.chooseValue.ids[i] = {
                            data: this.fileData[j],
                            dataId: j
                        };
                        break;
                    }
                }
            }
            for (var i = 0; i < this.options.value.links.length; i++)
                this.chooseValue.links[i] = this.options.value.links[i];
        },
        setValue: function() {
            this.options.value = {
                ids: [],
                links: []
            };
            for (var i = 0; i < this.chooseValue.ids.length; i++) {
                this.options.value.ids[i] = this.chooseValue.ids[i].data._id;
            }
            for (var i = 0; i < this.chooseValue.links.length; i++) {
                this.options.value.links[i] = this.chooseValue.links[i];
            }
        },
        getTempValueId: function() {
            var tempChooseValue = {
                ids: [],
                links: []
            };
            for (var i = 0; i < this.chooseValue.ids.length; i++)
                tempChooseValue.ids[i] = this.chooseValue.ids[i].data._id;
            tempChooseValue.links = this.chooseValue.links;
            console.log(tempChooseValue);
            return tempChooseValue;
        }
    });
})(jQuery)