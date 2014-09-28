//=require jquery.fancybox.pack
//=require jQuery.blockUI
//=require jquery.SuperSlide
//=require jquery.zclip
//=require jquery.highlight
//=require jquery-powerFloat-min
//=require ui/widgets/od_share
//=require ui/plugins/od_enter
//=require faye

$(document).ready(function() {
    var partial_ul = null;
    var share_imgs = null;
    $.form.powerfloat();

    $.each([$('.share-btn'), $('a.old')], function() {
        $(this).click(function() {
            $.od.odShare({
                point: $(this).attr('data'),
                survey_title: $(this).attr('s_title'),
                scheme_id: $(this).attr('scheme_id'),
                images: $(this).parents('li').find('a.unfold-btn').attr('prize_src')
            });
        });
    })

    jQuery(".slider").slide({
        mainCell: ".bd ul",
        effect: "leftLoop",
        delayTime: 3000,
        interTime: 6000,
        autoPlay: true
    });

    $('input, textarea').placeholder();

    $('.quill .unfold-btn').toggle(function() {
        $(this).children('i').removeClass('open').addClass('close').next('span').html('收起');
        $(this).parents('.research-meta').siblings('.reward_list').show();
    }, function() {
        $(this).children('i').removeClass('close').addClass('open').next('span').html('展开');
        $(this).parents('.research-meta').siblings('.reward_list').hide();
    })


    $(".pop").fancybox({
        beforeShow: function() {
            $(".fancybox-skin").css({
                "backgroundColor": "#fff"
            });
            var target_id = $(this.element).attr('href');
            var slides = $("div" + target_id).find('.slide');
            slides.removeClass('current_slide');
            $(slides[this.index]).addClass('current_slide')
            if (this.index == 0) {
                $(this.tpl.prev).appendTo($.fancybox.outer).css({
                    "opacity": 0.6
                });
                $('.fancybox-prev').children('span').css({
                    "background": "url(/assets/image/sample/prev_e.jpg)",
                    "background-repeat": "no-repeat"
                })
            } else if (this.index < this.group.length) {
                $(this.tpl.next).appendTo($.fancybox.outer).css({
                    "opacity": 0.6
                });
                $(".fancybox-next").children('span').css({
                    "background": "url(/assets/image/sample/next_e.jpg)",
                    "background-repeat": "no-repeat"
                })
            }
        },
        afterShow: function() {
            var target_id = $(this.element).attr('href');
            var slides = $("div" + target_id).find('.slide');
            slides.removeClass('current_slide');
            $(slides[this.index]).addClass('current_slide')
        },
        autoPlay: false,
        nextEffect: 'none',
        prevEffect: 'none',
        width: 654,
        height: 362,
        scrolling: 'no',
        padding: [20, 28, 20, 28],
        closeBtn: true,
        arrows: true,
        loop: false
    });


    $('.express a.unfold-btn').click(function() {
        $('.express .reward_list li:first .pop').click()
    })

    $('.paid-survey a').click(function() {
        page = $(this).parent('.page')
        count = parseInt(page.attr('click'));
        survey_list = $('.express ul li.research-content');
        survey_length = survey_list.length;
        if (survey_length > 2) {
            if ($(this).hasClass('prev') && count > 0) {
                // top_v = (count - 1) * 80;
                top_v = parseInt(survey_list.css('top')) + 80;
                survey_list.animate({
                    top: top_v + 'px'
                }, 500)
                survey_list.filter('.express_' + count).removeClass('have-border');
                count -= 1;
                page.attr('click', count);
            } else if ($(this).hasClass('next') && count < survey_length - 2) {
                survey_list.filter('.express_' + (count + 1)).addClass('have-border');
                top_v = -(count + 1) * 80;
                survey_list.animate({
                    top: top_v + 'px'
                }, 500)
                count += 1;
                page.attr('click', count);
            }
        }
    })


    $('.gift_slide a.next').on('click', function() {
        $('.gift-list .gift-img').append('<span class="loading"><img src="/assets/od-quillme/s_loading.gif " alt="loading"></span>')
        var p = $(this).attr('page');

        setTimeout(function() {
            $.ajax({
                type: "get",
                url: '/home/gifts',
                data: {
                    page: p
                }
            });
        }, 500);
    })

    faye = new Faye.Client(FAYE_SERVER_URL)
    faye.subscribe('/realogs/new', function(data) {
        var ul = $('ul.forums-list');
        $(data['log']).prependTo('ul.forums-list');
        ul.find('li:first').css("opacity", 0);
        ul.find('li:first').animate({
            opacity: 1
        }, 800)
        ul.find('li:last').remove();
        ul.find('li:last').css({
            'border-bottom': 'none'
        });

        $.each(ul.find('li').not('li:first'), function(k, v) {
            $(this).find('.time').text(data['other_times'][k])
        })
    });

    //投票页面
    var aLi = $('#being-hit li');
    aLi.each(function(index, el) {
        if((index+1)%4==0){
            $(el).css('margin-right','0');
        };
    });



















});