//=require 'jquery.fancybox.pack'

jQuery(function($) {
    $('.part-right .data .tab').mouseover(function(){
        $(this).addClass('active');
    }).mouseout(function(){
        $(this).removeClass('active');
    });

    // right partial avatar link
    $(".avatar").mouseover(function(){
        $('.avatar .change_avatar').css('visibility','visible');
    }).mouseout(function(){
         $('.avatar .change_avatar').css('visibility','hidden');
    });

    $(".fancybox").fancybox({
        beforeShow: function(){
            $(".fancybox-skin").css({"backgroundColor":"#fff"});
        }
    });

    // binding click link
    $('.bindings').on('click', 'i.icon-binding', function(){
        window.location.replace('/users/setting/bindings');
    })

    // remove error class when click on input tag
    $('input:not([type=button]), textarea').focus(function(){
        $(this).removeClass('error');
    })

    // control right patial select tab css
    $(".user-tabs .dashed-line").css('visibility', 'visible');
    $(".user-tabs .tab.active").prev('.dashed-line').css('visibility', 'hidden');
    $(".user-tabs .tab.active").next('.dashed-line').css('visibility', 'hidden');

    // when table tbody has none tr line
    // append comment
    if( $('.table-box table tbody tr').length == 0 ) {
        $('.table-box').append('<div style="text-align: center; color: #999; padding-top: 20px; font-size: 12px;">尚未存在任何记录，感谢参与本社区调研!</div>')
    }

    // Popup
    jQuery.extend({
        popupFancybox: function(options){
            var _defaults = {
                success: false,
                cont: '操作失败，请重新操作'
            }
            var _options = $.extend(_defaults, options);

            if (_options.success){
                html = '<div id="popup-success" class="popup" >'+
                    '<div class="detail-title">提示信息'+
                '</div>'+
                '<div style="clear: both;"></div>'+
                '<div class="cont" style="text-align: center;">'+
                    '<p>'+
                        '<span class="icon icon-green-ok"></span>'+
                        '<span class="c-green">'+_options.cont+'</span>'+
                    '</p>'+
                '</div>'+
                '<div class="actions">'+
                    '<a class="btn btn-over">我知道了</a>'+
                '</div>'+
                '</div>'

                $('body').append(html);
                $.fancybox($('#popup-success'), 
                    {
                        beforeShow: function(){
                            $(".fancybox-skin").css({"backgroundColor":"#fff"});
                        }
                    }
                );
            }else{
                html = '<div id="popup-fail" class="popup" >'+
                    '<div class="detail-title">提示信息'+
                '</div>'+
                '<div style="clear: both;"></div>'+
                '<div class="cont" style="text-align: center;">'+
                    '<p>'+
                        '<span class="icon icon-red-error"></span>'+
                        '<span class="c-red">'+_options.cont+'</span>'+
                    '</p>'+
                '</div>'+
                '<div class="actions">'+
                    '<a class="btn btn-over">我知道了</a>'+
                '</div>'+
                '</div>'

                $('body').append(html);
                $.fancybox($('#popup-fail'), 
                    {
                        beforeShow: function(){
                            $(".fancybox-skin").css({"backgroundColor":"#fff"});
                        }
                    }
                );
            }
        } 
    });

    $('body').on('click', 'a.btn-over', function(){
        // console.log('................close...')
        $.fancybox.close();
        $('.popup-fancybox').remove();
    }); 

    $('.part-left div, .part-left span, .part-left i').not(".select, .select-content, .select-txt, .triangle").unbind('click').click(function(){
        $('.select ul').css('display', 'none');
        $('.select').removeClass('active');
        // return false;
    })

    $('.part-left').unbind('click').on('click', '.select .select-content', function(){
        $('.select ul').css('display', 'none');
        $(this).parent('.select').addClass('active');
        $(this).parent('.select').children('ul').css('display', 'inline-block');
        return false;
    });

    $('.select ul').unbind('click').on('click', 'li', function(event){
        var _name = $(this).attr('name');
        var _txt = $(this).text();
        if (_name != undefined) {
            $(this).parent('ul').prev('.select-content').find('.select-txt')
                .text($(this).text()).attr('name', _name).attr('title',_txt);
        }else{
            $(this).parent('ul').prev('.select-content').find('.select-txt')
                .text($(this).text());
        }
        $('.select ul').css('display', 'none');
        $(this).parent('ul').parent('.select').removeClass('active');
    })
});