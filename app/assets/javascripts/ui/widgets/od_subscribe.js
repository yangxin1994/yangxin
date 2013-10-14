//=require ./_base
//=require jquery.fancybox.pack
//=require ui/plugins/od_enter
//=require ./_templates/od_subscribe
(function($) {
    $('input, textarea').placeholder();

    var $this = null;
    $.odWidget('odSubscribe', {
        options: {
            email_mobile: null,
            btn: null
        },
        _create: function() {
            this.element = this.hbs(this.options);
            $this = this;
            if (this.options.email_mobile) {
                this._make_rss_activate(this.options.email_mobile, this.options.btn, this);
            } else {
                this._popup($this._find('#fill_email_mobile'));
            }
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
                        button.html('').append('<img style="margin-top:2px;"src="/assets/od-quillme/rss_loading.gif">').addClass('disabled')
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
                                obj._popup($this._find('#mail_success'), channel, mail_to)
                            } else {
                                obj._popup($this._find('#mobile_success'), channel, null)
                            }
                        } else {
                            if ($.regex.isEmail(channel)) {
                                obj._popup($this._find('#email_finish'))
                            } else {
                                obj._popup($this._find('#mobile_finish'))
                            }

                        }
                    } else {
                        //订阅过程出错提示页
                        obj._popup($this._find('#rss_error'))
                    }
                }
            });
        },
        _mobile_rss_activate: function() {
            var butt = $('button.next_f');
            var channel = $('.mobi').text();
            var code = $('input[name="code"]').val()
            if (code.length > 5) {
                $.ajax({
                    type: "get",
                    url: '/surveys/mobile_rss_activate',
                    data: {
                        rss_channel: channel,
                        code: code
                    },
                    beforeSend: function() {
                        butt.next('span').remove();
                    },
                    success: function(retval) {
                        butt.next('span').remove();
                        if (retval.success) {
                            $this._popup($this._find('#mobile_finish'))
                        } else {
                            butt.next('.code_exp').show();
                        }
                    }
                })
            } else {
                $('input[name="code"]').focus();
            }
        },
        _fill_email_mobile: function() {
            email_mobile = $('input.email_mobile').val();
            if ($.regex.isEmail(email_mobile) || $.regex.isMobile(email_mobile)) {
                this._make_rss_activate(email_mobile, null, this)
            } else {
                $('input.email_mobile').prev('.channel_err').show();
            }
        },
        _before_show_option:function(obj, channel, mail_to){
            if ($('input.email_mobile').length > 0) {
                $('input.email_mobile').on('focus', function() {
                    $('input.email_mobile').prev('.channel_err').hide();
                })
            }

            if ($('button.subsc').length > 0) {
                $('button.subsc').on('click', function() {
                    $this._fill_email_mobile();
                })
            }

            if ($('a.re_mobile').length > 0) {
                $('a.re_mobile').on('click', function() {
                    $this._re_generate_email_activate($('a.re_mobile'), channel);
                })
            }

            if ($('button.next_f').length > 0) {
                $('button.next_f').on('click', function() {
                    $this._mobile_rss_activate();
                })
            }

            if ($('input[name="code"]').length > 0) {
                $('input[name="code"]').on('focus', function() {
                    $('button.next_f').next('.code_exp').hide();
                });
            }

            if ($('a.re_mail').length > 0) {
                $('a.re_mail').on('click', function() {
                    var mail = $('span.mail').text();
                    $this._re_generate_email_activate($('a.re_mail'), mail);
                })
            }

            if ($('button.mail_act_now').length > 0) {
                $('button.mail_act_now').on('click', function() {
                    var link = $(this).attr('href');
                    window.location.href = link;
                })

            }

            if($('button.close_f').length > 0){
                 $('button.close_f').live('click', function() {
                    $.fancybox.close();
                 })   
            }

            if ($('span.mail').length > 0) {
                $('span.mail').text(channel)
                $('button').attr('href', mail_to)
            }

            if ($('span.mobi').length > 0) {
                $('span.mobi').text(channel)
            }
        },
        _popup: function(obj, channel, mail_to) {
            $.fancybox.open([obj], {
                beforeShow: function() {
                    $(".fancybox-skin").css({
                        "backgroundColor": "#fff"
                    });

                    $this._before_show_option(obj, channel, mail_to);

                    $('a.re_mail').next('span').remove();
                    $('a.re_mobile').next('span').remove();

                },
                afterClose: function() {
                    $this._destroy();
                },
                width: 500,
                height: 180,
                scrolling: 'no'
            });
        },
        _re_generate_email_activate: function(obj, email) {
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
        },
        _destroy: function() {
            if (this.options.btn) {
                this.options.btn.html('订阅').removeClass('disabled')
            }
            $.Widget.prototype.destroy.call(this);
        }
    })
})(jQuery)