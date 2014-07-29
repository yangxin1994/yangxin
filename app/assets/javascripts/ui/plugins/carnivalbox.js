//=require 'jquery.fancybox.pack'

jQuery.extend({
    carnivalbox: function(options) {
        var _defaults = {
            showTitle: false,
            showClose: false,
            title: '',
            content: '',
            btnCont: '',
            width: 0,
            beforeshow: function() {
                return false
            },
            aftershow: function() {
                return false
            },
            beforeclose: function() {
                return false
            },
            afterclose: function() {
                $('.carnival-popup a.btn').die("click");
                $('.carnival-popup').remove();
            }
        }
        var _options = $.extend(_defaults, options);
        $('.carnival-popup').remove();

        html = '<div class="carnival-popup"><div class="notic"></div><h2>' + _options.title + '</h2><p>' + _options.content + '</p><a href="javascript:void(0);" class="btn submit">' + _options.btnCont + '</a></div>'

        $('body').append(html);

        $.fancybox($('.carnival-popup'), {
            padding: 0,
            minWidth: _options.width,
            openEffect: 'none',
            closeEffect: 'none',
            showCloseButton: _options.showClose,
            helpers: {
                overlay: {
                    locked: false,
                    closeClick: false,
                    css: {
                        'background': 'rgba(51, 51, 51, 0.2)'
                    }
                }
            },
            beforeShow: function() {
                _options.beforeshow();
            },
            afterShow: function() {
                _options.aftershow();
            },
            beforeClose: function() {
                _options.beforeclose();
            },
            afterClose: function() {
                _options.afterclose();
            }
        });

    }
});