//=require 'jquery.fancybox.pack'

jQuery.extend({
    carnivalbox: function(options) {
        var _defaults = {
            title: null,
            success: false,
            cont: '操作失败，请重新操作'
        }
        var _options = $.extend(_defaults, options);

        $('#popup-success, #popup-fail').remove();
        if (_options.success) {
            html = '<div id="popup-success" class="popup" >' +
                '<div class="detail-title">提示信息' +
                '</div>' +
                '<div style="clear: both;"></div>' +
                '<div class="cont" style="text-align: center;">' +
                '<p>' +
                '<span class="icon icon-green-ok"></span>' +
                '<span class="c-green">' + _options.cont + '</span>' +
                '</p>' +
                '</div>' +
                '<div class="actions">' +
                '<a class="btn btn-over">我知道了</a>' +
                '</div>' +
                '</div>'

            $('body').append(html);
            $.fancybox($('#popup-success'), {
                beforeShow: function() {
                    $(".fancybox-skin").css({
                        "backgroundColor": "#fff"
                    });
                }
            });
            $('#popup-success .btn.btn-over').focus();
        } else {
            html = '<div id="popup-fail" class="popup" >' +
                '<div class="detail-title">提示信息' +
                '</div>' +
                '<div style="clear: both;"></div>' +
                '<div class="cont" style="text-align: center;">' +
                '<p>' +
                '<span class="icon icon-red-error"></span>' +
                '<span class="c-red">' + _options.cont + '</span>' +
                '</p>' +
                '</div>' +
                '<div class="actions">' +
                '<a class="btn btn-over">我知道了</a>' +
                '</div>' +
                '</div>'

            $('body').append(html);
            $.fancybox($('#popup-fail'), {
                beforeShow: function() {
                    $(".fancybox-skin").css({
                        "backgroundColor": "#fff"
                    });
                }
            });
            $('#popup-fail .btn.btn-over').focus();
        }
    }
});