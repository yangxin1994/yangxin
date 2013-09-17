//=require ./_base
//=require jquery.fancybox.pack
//=require ui/plugins/od_enter
//=require ./_templates/od_subscribe
(function($) {
    $.odWidget('odSubscribe', {
        options: {
            email_mobile: null,
            btn: null
        },
        _create: function() {
            this.element = this.hbs(this.options);

            if (this.options.email_mobile) {
                this._make_rss_activate(this.options.email_mobile, this.options.btn, this);
            } else {
                this._popup('#fill_email_mobile');
            }

            console.log("--------------------------")
            console.log(this._find('a.re_mobile'))
            this._find('a.re_mobile').addClass('ddd')
            console.log("--------------------------")

        },
        _make_rss_activate: function(channel, button, obj) {
            $.ajax({
                type: "POST",
                url: '/surveys/generate_rss_activate_code',
                data: {
                    rss_channel: channel
                },
                beforeSend: function() {
                    if (button) {
                        button.html('').append('<imgstyle="margin-top:2px;"src="/assets/od-quillme/rss_loading.gif">').addClass('disabled')
                    }
                },
                success: function(retval) {
                    if (retval['success']) {
                        if (retval['new_user']) {
                            if ($.regex.isEmail(channel)) {
                                if (channel.indexOf('gmail.com') > -1) {
                                    var mail_to = 'http://gmail.com';
                                } else if (channel.indexOf('@tencent.') > -1) {
                                    var mail_to = 'http://mail.qq.com';
                                } else if (channel.indexOf('@qq.') > -1) {
                                    var mail_to = 'http://mail.qq.com';
                                } else {
                                    var mail_to = 'http://mail.' + channel.split('@')[1];
                                }
                                //邮件订阅成功提示页
                                obj._popup('#mail_success', channel, mail_to)
                            } else {
                                obj._popup('#mobile_success', channel, null)
                            }
                        } else {
                            if ($.regex.isEmail(channel)) {
                                obj._popup('#email_finish')
                            } else {
                                obj._popup('#mobile_finish')
                            }

                        }
                    } else {
                        //订阅过程出错提示页
                        obj._popup('#rss_error', null, null)
                    }
                }
            });
        },
        _popup: function(obj, channel, mail_to) {
            $.fancybox.open([{
                href: obj
            }], {
                beforeShow: function() {
                    $(".fancybox-skin").css({
                        "backgroundColor": "#fff"
                    });
                    if ($('span.mail').length > 0) {
                        $('span.mail').text(channel)
                        $('button').attr('href', mail_to)
                    }

                    if ($('span.mobi').length > 0) {
                        $('span.mobi').text(channel)
                    }

                    $('a.re_mail').next('span').remove();
                    $('a.re_mobile').next('span').remove();

                },
                afterClose: function() {
                    $('a.rss-btn').html('订阅').removeClass('disabled');
                    $('input[name="code"]').val('');
                    $('.code_exp').hide();
                },
                width: 500,
                height: 180,
                scrolling: 'no'
            });
        },
        _re_generate_email_activate: function(obj, email) {
            console.log("-----------------------")
            console.log(obj)
            console.log("-----------------------")
            $.ajax({
                type: "POST",
                url: '/surveys/generate_rss_activate_code',
                data: {
                    rss_channel: email
                },

                beforeSend: function() {
                    obj.next('img').remove();
                    if (obj.next('img').length < 1) {
                        if ($.regex.isEmail(email)) {
                            obj.after('<img class="loading" src="/assets/image/sample/fancybox_loading@2x.gif" width="16" height="16" style="position:absolute;left:64px;top:44px;" />')
                        } else {
                            obj.after('<img class="loading" src="/assets/image/sample/fancybox_loading@2x.gif" width="16" height="16" style="position:absolute;right:50px;top:8px;" />')
                        }

                    }
                },
                success: function(retval) {
                    obj.next('img').remove();
                    if ($.regex.isEmail(email)) {
                        obj.after('<img class="loading" src="/assets/od-quillme/success.png" width="16" height="16" style="position:absolute;left:64px;top:44px;" />')
                    } else {
                        obj.after('<img class="loading" src="/assets/od-quillme/success.png" width="16" height="16" style="position:absolute;rigt:50px;top:9px;" />')
                    }
                }
            });
        }
    })
})(jQuery)