//=require jquery.placeholder
//=require jquery.cookie
//=require ui/widgets/od_subscribe
jQuery(function($) {

    //如果用户已经关闭了安装插件提示，那么24小时内不再提示安装
    if ($.cookie('ignore_plugin')) {
        $('div.hot-research-banner').remove();
    }

    //用户点击关闭安装插件提示，生成cookie，记录用户决定
    $('.hot-research-banner .popup-close').click(function() {
        $(this).parent('.hot-research-banner').remove();
        // write cookie 
        $.cookie('ignore_plugin', 'true', {
            expires: 1
        });
    })

    //相应回车提交表单事件

    function commit_rss() {
        $('.rss-btn').click();
    }
    $('input[name="contact"]').odEnter({
        enter: commit_rss
    });

    //下拉框点击事件
    $("body").click(function(e) {
        var select = $(e.target).hasClass('select') || $(e.target).parents('div').hasClass('select')
        if (select && $(e.target).prop('tagName') != 'LI') {
            $(e.target).closest('.select-content').addClass('active').siblings('ul').show()
        } else {
            $('.select-content').siblings('ul').hide()
            $('.select-content').removeClass('active')
        }
    })


    var select = $('div.select')
    if (select.length > 0) {
        $(select).toggle(function() {
            if ($(this).children('ul').is(':visible')) {
                $(this).children('.select-content').removeClass('active').end().children('ul').hide()
            } else {
                $(this).children('.select-content').addClass('active').end().children('ul').show()
            }
        }, function() {
            if ($(this).children('ul').is(':visible')) {
                $(this).children('.select-content').removeClass('active').end().children('ul').hide()
            } else {
                $(this).children('.select-content').addClass('active').end().children('ul').show()
            }
        })
    }


    //下拉框选项点击事件
    $('.select-content').next('ul').children('li').click(function() {
        $('span.select-txt').attr('data', $(this).attr('data')).text($(this).text())
        var status = ($.util.param('status') ? ($.util.param('status')) : '')
        var reward_type = ($.util.param('reward_type') ? ($.util.param('reward_type')) : '')
        var answer_status = $(this).attr('data')
        window.location.href = "/surveys?status=" + status + "&reward_type=" + reward_type + "&answer_status=" + answer_status
    })

    //订阅按钮
    $('input[name="contact"]').next('a').click(function() {
        var channel = $('input[name="contact"]').val();
        if ($.regex.isEmail(channel) || $.regex.isMobile(channel)) {
            $.od.odSubscribe({
                email_mobile: channel,
                btn: $(this)
            })
        } else {
            $('input[name="contact"]').prev('.channel_err').show();
        }
    })

    $('input[name="contact"]').focus(function() {
        $(this).prev('.channel_err').hide();
    })
});