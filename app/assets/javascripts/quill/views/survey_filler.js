//=require ./base
//=require ../models/survey
//=require ./fillers
//=require ui/widgets/od_popup
//=require ui/widgets/od_share
//=require ui/plugins/od_button_text
//=require ui/plugins/od_enter
//=require jquery.scrollTo
//=require jquery.cookie.js
//=require ../templates/survey_filler_qs
//=require ../templates/survey_filler_submit
//=require ../templates/survey_filler_redo
//=require ../templates/survey_filler_reject
//=require ../templates/survey_filler_end_free
//=require ../templates/survey_filler_end_point_finish
//=require ../templates/survey_filler_end_point_review
//=require ../templates/survey_filler_end_money
//=require ../templates/survey_filler_end_money_finish
//=require ../templates/survey_filler_end_lottery
//=require ../templates_en/survey_filler_qs
//=require ../templates_en/survey_filler_submit
//=require ../templates_en/survey_filler_redo
//=require ../templates_en/survey_filler_reject
//=require ../templates_en/survey_filler_end_free
//=require ../templates_en/survey_filler_end_point_finish
//=require ../templates_en/survey_filler_end_point_review
//=require ../templates_en/survey_filler_end_money
//=require ../templates_en/survey_filler_end_money_finish
//=require ../templates_en/survey_filler_end_lottery

$(function() {

    var gonganbu = '52a59fc6eb0e5bb2c5000007',
        renmin = ''

        /* Survey filer
         * options:
         *    answer_id: string, if null, the user has not started answer the survey
         *		data: the init data for the filler
         *		is_preview: bool,
         *		reward: { reward_scheme_type, reward_point, reward_money, prizes},
         *		signin: bool
         *		email:
         *		mobile:
         *		spread_point: -1
         *		spread_url:
         *		binded:
         * =========================== */
    quill.quillClass('quill.views.SurveyFiller', quill.views.Base, {

        _initialize: function() {
          // en
          if(this.options.lang == 'en')
            this._template_path = 'templates_en';
          // spread point
          if (this.options.spread_point == undefined)
              this.options.spread_point = 0;
        },

        _uri: function(path) {
            return '/answers/' + this.options.answer_id + (path || '') + '.json';
        },

        _error: function(msg) {
            $.od.odPopup({
                content: msg
            });
        },

        _spread: function() {
            if (this.options.spread_point <= 0) return;
            $.od.odShare({
                point: this.options.spread_point,
                survey_title: this.model.get('title'),
                scheme_id: this.options.reward.id,
                images: "" //TODO: images for lottery
            });
        },

        _close: function() {
            // close window or redirect
            var link = this.model.get('style_setting').redirect_link;
            if ($.regex.isUrl(link)) {
                link = link.toLowerCase();
                if (link.indexOf('http') != 0)
                    link = 'http://' + link;
                location.href = link;
            } else {
                var opened = window.open('about:blank', '_self');
                opened.opener = null;
                opened.close();
            }
        },

        _render: function() {
            if(this.options.is_preview) {
              // restart preview button
              $('#pv_bar button.replay-btn').show().click($.proxy(function() {
                  $.deleteJSON(this._uri('/destroy_preview'), $.proxy(function(retval) {
                      if (retval.success)
                        location.href = '/p/' + this.options.reward.id;
                      else
                        this._error(this.options.lang == 'en' ? 'Error. Please refresh page' : '操作失败，请刷新页面重试。');
                  }, this));
              }, this));
            } else {
              // reanswer or start new answer
              var restart_ref = '/s/' + this.options.reward.id;
              if(this.options.is_agent)
                restart_ref += ('?ati=' + this.options.agent_task_id);
              $('#pv_bar button.replay-btn').show().click($.proxy(function() {
                  $.deleteJSON(this._uri('/replay'), $.proxy(function(retval) {
                      if (retval.success)
                        location.href = restart_ref;
                      else
                        this._error(this.options.lang == 'en' ? 'Error. Please refresh page' : '操作失败，请刷新页面重试。');
                  }, this));
              }, this));
              $('#pv_bar a.signout-btn').show().attr('href', '/account/sign_out?ref=' + restart_ref);
              $('#pv_bar button.newanswer-btn').show().click($.proxy(function() {
                // hack to get domain root
                var hn = location.hostname.split('.');
                $.cookie(this.model.get('_id') + '_0', null, { domain: '.' + hn[hn.length - 2] + '.' + hn[hn.length - 1], path: '/' });
                location.href = restart_ref;
              }, this));
            }

            // Setup page
            this._setup(this.options.data);
        },

        /* Load questions
         * =========================== */
        load_questions: function(start_from_question, load_next_page) {
            $.getJSON(this._uri('/load_questions'), {
                start_from_question: start_from_question,
                load_next_page: load_next_page
            }, $.proxy(function(retval) {
                this._setup(retval);
            }, this));
        },

        /* Setup page dom using this.options.data
         * =========================== */
        _setup: function(data) {
            // If not success
            if (data == null || !data.success) {
              this._error(this.options.lang == 'en' ? 'Failed to load question. Please refresh page.' : '加载问题出错，请刷新页面重试。');
              return;
            }

            // If success, setup page
            $('#f_body').empty();
            var value = data.value;
            value.answer_status == 1 ? $('#progress_con').show() : $('#progress_con').hide(); // hide progress bar 
            if (value.answer_status == 1) {
                // answer_status: 1（正在回答）
                // setup questions
                var questions = value.questions,
                    answers = value.answers,
                    total_count = value.question_number,
                    index = value.answer_index,
                    time = value.estimate_answer_time,
                    redo_count = value.repeat_time,
                    answer_index_all = value.answer_index_all;

                // setup question or submit page
                if (questions.length == 0) {
                    // Question.length == 0. Should submit answer

                    // update progress
                    this._updateProgress(1);

                    // setup page
                    this.hbs({
                        remind: redo_count > 0,
                        title: this.model.get('title'),
                        allow_pageup: this.model.get('style_setting').allow_pageup
                    }, 'survey_filler_submit').appendTo($('#f_body'));

                    // set prev and next button event
                    var check_btn = $('#check_btn'),
                        submit_btn = $('#submit_btn');

                    // check answer from page one when click on check button
                    check_btn.click($.proxy(function() {
                        $.util.disable(check_btn, submit_btn);
                        check_btn.text(this.options.lang == 'en' ? 'Loading...' : '正在加载问题...');
                        this.load_questions(-1, true);
                    }, this));

                    // submit answer when click on submit button
                    submit_btn.click($.proxy(function() {
                      $.util.disable(check_btn, submit_btn);
                      submit_btn.text(this.options.lang == 'en' ? 'Submitting...' : '正在提交答案...');
                      $.postJSON(this._uri('/finish'), $.proxy(function(retval) {
                          this.load_questions(-1, true);
                      }, this));
                    }, this));

                } else {
                    // update progress
                    this._updateProgress(index / total_count);

                    // setup survey filler container
                    this.hbs({
                        remind: redo_count > 0,
                        header: this.model.get('header'),
                        footer: this.model.get('footer'),
                        title: index == 0 ? this.model.get('title') : false,
                        allow_pageup: this.model.get('style_setting').allow_pageup
                    }, 'survey_filler_qs').appendTo($('#f_body'));

                    // Setup questions fillers
                    var idx = index;
                    for (var i = 0; i < questions.length; i++) {
                        var model = this.model.setQuestionModel(questions[i]);
                        if (quill.helpers.QuestionType.getName(model.get('question_type')) == 'Paragraph') idx--;
                        var filler = new quill.views.fillers[quill.helpers.QuestionType.getName(questions[i].question_type)]({
                            model: model,
                            index: idx++,
                            lang: this.options.lang
                        }).appendTo($('#questions_con'));
                        filler.$('.q-render-btns').remove();
                        filler.setAnswer(answers[model.id]);
                    };
                    if (index > 0)
                        $('.q-filler:eq(0)').addClass('top');
                    $('.q-filler:last').addClass('bottom');
                    if (!this.model.get('style_setting').has_question_number)
                        $('#questions_con .q-idx').hide(); // hide q-idx if necessary

                    // Setup next and previous buttons
                    var next_btn = $('#next_btn'),
                        prev_btn = $('#prev_btn');
                    // Disable next button for some time (don't disable it for allow_pageup==true survey, or previewing)
                    var has_not_empty_answer = (_.find(answers || [], function(a) {
                        return a != null;
                    }) != null);
                    if (!this.options.is_preview && !this.model.get('style_setting').cancel_time_limit && (prev_btn.length == 0 || !has_not_empty_answer)) {
                        $.util.disable(next_btn);
                        var old_text = next_btn.text();

                        function _update_btn() {
                            if (time <= 0) {
                                next_btn.text(old_text);
                                $.util.enable(next_btn);
                            } else {
                                next_btn.text(old_text + "（" + time + "）");
                                time--;
                                setTimeout(_update_btn, 1000);
                            }
                        }
                        _update_btn();
                    };
                    // Set previous and next button event
                    next_btn.click($.proxy(function() {
                        $.util.disable(next_btn, prev_btn);
                        // submit question answers
                        // 1. get answers
                        var answer_content = {}, error_filler = null;
                        $('.q-filler').each(function(i, v) {
                            var filler = $(this).data('view');
                            var result = filler.getAnswer();
                            if (!error_filler && result.error) error_filler = filler;
                            answer_content[filler.model.id] = result.answer;
                        });
                        if (error_filler) {
                            // 2. if there is any illegal answer, alert
                            $(window).scrollTo(error_filler.$el, 500, {
                                offset: {
                                    top: -60
                                }
                            });
                            $.util.enable(prev_btn, next_btn);
                        } else {
                            // 3. submit answers
                            next_btn.text(this.options.lang == 'en' ? 'Submtting...' : '正在提交答案...');
                            $.util.disable(prev_btn, next_btn);
                            $.putJSON(this._uri(), {
                                answer_content: answer_content
                            }, $.proxy(function(retval) {
                                if (retval && retval.success) {
                                    next_btn.text(this.options.lang == 'en' ? 'Loading...' : '正在加载问题...');
                                    this.load_questions((questions.length > 0) ?
                                        questions[questions.length - 1]['_id'] : -1, true);
                                } else {
                                    location.reload(true);
                                }
                            }, this));
                        }
                    }, this));
                    prev_btn.click($.proxy(function() {
                        $.util.disable(next_btn, prev_btn);
                        // load prev page questions
                        prev_btn.text(this.options.lang == 'en' ? 'Loading...' : '正在加载上一页问题...');
                        this.load_questions((questions.length > 0) ? questions[0]['_id'] : -1, false);
                    }, this));
                    if (answer_index_all == 0) prev_btn.hide();
                }
            } else if (value.answer_status == 4 || value.answer_status == 8 || value.answer_status == 32) {
                // answer_status: 4（待审核），8（等待代理审核），32（完成）
                if (this.options.reward.reward_scheme_type == 0) {
                    // hack for survey carnival
                    if (!this.options.is_preview && this.model.get('style_setting').redirect_link == 'carnival') {
                        var d = new Date();
                        location.href = "/carnival/campaigns?t=" + d.getTime();
                        return;
                    }
                    // end hack
                    // free, show message
                    this.hbs({
                        title: this.model.get('title'),
                        survey_id: this.model.get('_id'),
                        publish_result: this.model.get('publish_result'),
                        spreadable: this.options.spread_point > 0,
                        agent: this.options.is_agent,
                        spread_point: this.options.spread_point,
                        show_subscribe: !this.options.binded && this.model.get('_id') != gonganbu
                    }, 'survey_filler_end_free').appendTo('#f_body');
                    $('#start_spread').click($.proxy(function() {
                        this._spread();
                    }, this));
                    $('#close_btn').click($.proxy(function() {
                        this._close();
                    }, this));
                } else if (this.options.reward.reward_scheme_type == 1) {
                    // cash
                    if (value.order_id == null) {
                        // ask for order 
                        this.hbs({
                            title: this.model.get('title'),
                            reward_money: this.options.reward.reward_money,
                            reward_money_jfb: this.options.reward.reward_money * 100,
                            signin: this.options.signin,
                            survey_id: this.model.get('_id'),
                            publish_result: this.model.get('publish_result')
                        }, 'survey_filler_end_money').appendTo('#f_body');
                        $('.award_money ul li').hover(function() {
                                $(this).addClass('hover');
                            },
                            function() {
                                $(this).removeClass('hover');
                            }).click(function() {
                            $('.award_money ul li').removeClass('active');
                            $(this).addClass('active');
                            refresh_award_info(true);
                        });
                        var ok_btn = $('#ok_btn'),
                            account_ipt = $('.award_money_info input'),
                            error_con = $('.award_money_info .ami_error');
                        var infos = { //TODO: zhifubao != email
                            chongzhi: {
                                h1: '请输入您要充值的手机号',
                                h2: '您要充值的手机号是',
                                btn: '请输入正确的手机号',
                                btn_ok: '确认充值',
                                error__12: '此手机号已经参加过本次调研，不能重复充值。',
                                error__15: '此手机号已参加过' + window.config.corp_name + '其他调研，无法申请本热点调查奖励。',
                                ipt_value: this.options.mobile
                            },
                            zhifubao: {
                                h1: '请输入您的支付宝注册邮箱或手机号',
                                h2: '您要转账的支付宝账号是',
                                btn: '请输入正确的支付宝账号',
                                btn_ok: '确认向支付宝转账',
                                error__12: '此支付宝账号已经参加过本次调研，不能重复转账。',
                                error__15: '此支付宝账号已参加过' + window.config.corp_name + '其他调研，无法申请本热点调查奖励。',
                                ipt_value: this.options.email
                            },
                            jifenbao: {
                                h1: '请输入您的集分宝注册邮箱或手机号',
                                h2: '您的集分宝账号是',
                                btn: '请输入正确的集分宝账号',
                                btn_ok: '确认向集分宝转入积分',
                                error__12: '此集分宝账号已经参加过本次调研，不能重复转账。',
                                error__15: '此集分宝账号已参加过' + window.config.corp_name + '其他调研，无法申请本热点调查奖励。',
                                ipt_value: this.options.email
                            }
                        }

                            function _get_award_type() {
                                var award_type = null;
                                $('.award_money ul li').each(function(i, v) {
                                    if ($(this).hasClass('active')) {
                                        award_type = $(this).attr('id').split('_')[1];
                                        return false;
                                    }
                                });
                                return award_type;
                            }

                            function refresh_award_info(set_default) {
                                // find award_type
                                var award_type = _get_award_type();
                                // setup award info
                                if (award_type == null) {
                                    $('.award_money_info').hide();
                                    $.util.disable(ok_btn.text(this.options.lang == 'en' ? 'Choose method' : '请选择奖励兑换方式'));
                                    return;
                                }
                                $('.award_money_info').show();
                                $('.award_money_info h1').text(infos[award_type].h1 + '：');
                                $('.award_money_info h2 span').text(infos[award_type].h2);
                                error_con.text('');
                                $.util.disable(ok_btn.text(infos[award_type].btn));
                                // check input
                                var value = $.trim(account_ipt.val());
                                if (award_type == 'chongzhi' && $.regex.isEmail(value))
                                    value = '';
                                if (value == '' && set_default == true) {
                                    value = infos[award_type].ipt_value;
                                    account_ipt.val(value);
                                }
                                value ? $('.award_money_info h2').show() : $('.award_money_info h2').hide();
                                if ($.regex.isMobile(value)) {
                                    $('.award_money_info h2 em').text(value.substr(0, 3) + ' ' + value.substr(3, 4) + ' ' + value.substr(7, 4));
                                } else {
                                    $('.award_money_info h2 em').text(value);
                                }
                                if ($.regex.isMobile(value) || (award_type != 'chongzhi' && $.regex.isEmail(value))) {
                                    $.util.enable(ok_btn.text(infos[award_type].btn_ok));
                                }
                            }
                        account_ipt.keyup(refresh_award_info).blur(refresh_award_info);
                        ok_btn.click($.proxy(function() {
                            var award_type = _get_award_type();
                            ok_btn.odButtonText({
                                text: this.options.lang == 'en' ? 'Submitting...' : '正在提交订单...'
                            });
                            $.util.disable(ok_btn, account_ipt);
                            $.putJSON(this._uri('/select_reward'), {
                                type: award_type,
                                account: $.trim(account_ipt.val())
                            }, $.proxy(function(retval) {
                                if (retval.success) {
                                    location.reload(true);
                                } else {
                                    var error_msg = ((retval.value != null) ? infos[award_type][retval.value.error_code] : null);
                                    if (error_msg != null) {
                                        ok_btn.odButtonText('restore');
                                        $.util.enable(ok_btn, account_ipt);
                                        error_con.text(error_msg);
                                    } else {
                                        this._error(this.options.lang == 'en' ? 'Failed to submit order. Please refresh page.' : '订单提交失败，请刷新页面重试');
                                    }
                                }
                            }, this));
                        }, this));
                    } else {
                        // cash finished
                        this.hbs({
                            title: this.model.get('title'),
                            reward_money: this.options.reward.reward_money,
                            waiting: value.order_status != 4 && value.order_status != 8,
                            success: value.order_status == 4,
                            failed: value.order_status == 8,
                            order_code: value.order_code,
                            signin: this.options.signin,
                            survey_id: this.model.get('_id'),
                            publish_result: this.model.get('publish_result'),
                            spreadable: this.options.spread_point > 0,
                            spread_point: this.options.spread_point,
                            show_subscribe: !this.options.binded && this.model.get('_id') != gonganbu
                        }, 'survey_filler_end_money_finish').appendTo('#f_body');
                        $('#start_spread').click($.proxy(function() {
                            this._spread();
                        }, this));
                        $('#my_order_btn').click(function() {
                            location.href = '/users/orders';
                        });
                        var signin_btn = $('#signin_btn').click($.proxy(function() {
                            $.util.disable(signin_btn.text(this.options.lang == 'en' ? 'Redirecting...' : '正在跳转...'));
                            $.postJSON(this._uri('/start_bind'), function(retval) {
                                location.href = '/account/sign_in?ref=' + encodeURIComponent('/users/orders');
                            });
                        }, this));
                        $('#close_btn').click($.proxy(function() {
                            this._close();
                        }, this));
                    }
                } else if (this.options.reward.reward_scheme_type == 2) {
                    // point
                    this.hbs({
                        title: this.model.get('title'),
                        reward_point: this.options.reward.reward_point,
                        signin: this.options.signin,
                        survey_id: this.model.get('_id'),
                        publish_result: this.model.get('publish_result'),
                        spreadable: this.options.spread_point > 0,
                        spread_point: this.options.spread_point,
                        show_subscribe: !this.options.binded && this.model.get('_id') != gonganbu
                    }, (value.answer_status == 32) ? 'survey_filler_end_point_finish' : 'survey_filler_end_point_review').appendTo('#f_body');
                    $('#start_spread').click($.proxy(function() {
                        this._spread();
                    }, this));
                    $('#my_surveys_btn').click(function() {
                        location.href = '/users/surveys';
                    });
                    $('#my_rewards_btn').click(function() {
                        location.href = '/users/points';
                    });
                    var signin_btn = $('#signin_btn').click($.proxy(function() {
                        $.util.disable(signin_btn.text(this.options.lang == 'en' ? 'Redirecting...' : '正在跳转...'));
                        $.postJSON(this._uri('/start_bind'), function(retval) {
                            location.href = '/account/sign_in?ref=' + encodeURIComponent('/users/points');
                        });
                    }, this));
                } else if (this.options.reward.reward_scheme_type == 3) {
                    // lottery
                    this.hbs({
                        title: this.model.get('title'),
                        prizes: this.options.reward.prizes,
                        signin: this.options.signin,
                        survey_id: this.model.get('_id'),
                        publish_result: this.model.get('publish_result'),
                        spreadable: this.options.spread_point > 0,
                        spread_point: this.options.spread_point,
                        show_subscribe: !this.options.binded && this.model.get('_id') != gonganbu
                    }, 'survey_filler_end_lottery').appendTo('#f_body');
                    $('#start_spread').click($.proxy(function() {
                        this._spread();
                    }, this));
                    $('#ok_btn').click($.proxy(function() {
                        location.href = '/lotteries/' + this.options.answer_id;
                    }, this));
                }
            } else if (value.answer_status == 16) {
                // 重答
                this.hbs({
                    title: this.model.get('title'),
                    audit_message: value.answer_audit_message
                }, 'survey_filler_redo').appendTo($('#f_body'));
                var redo_btn = $('#redo_btn').click($.proxy(function() {
                    redo_btn.attr('disabled', 'disabled').text(this.options.lang == 'en' ? 'Loading...' : '正在准备重新答题...');
                    $.postJSON(this._uri('/clear'), $.proxy(function(retval) {
                        this.load_questions(-1, true);
                    }, this));
                }, this));
            } else if (value.answer_status == 2) {
                // 被拒绝
                // reject 1（配额已满），2（未通过自动质控），4（未通过人工质控），8（甄别题）或者16（超时）
                this.hbs({
                    title: this.model.get('title'),
                    filter: (value.answer_reject_type == 1 || value.answer_reject_type == 8),
                    quality: (value.answer_reject_type == 2),
                    review_failed: (value.answer_reject_type == 4),
                    timeout: (value.answer_reject_type == 16),
                    reject_reason: value.answer_audit_message,
                    survey_id: this.model.get('_id'),
                    publish_result: this.model.get('publish_result'),
                    spreadable: this.options.spread_point > 0,
                    spread_point: this.options.spread_point,
                    show_subscribe: !this.options.binded && this.model.get('_id') != gonganbu
                }, 'survey_filler_reject').appendTo('#f_body');
                $('#start_spread').click($.proxy(function() {
                    this._spread();
                }, this));
                $('#close_btn').click($.proxy(function() {
                    this._close();
                }, this));
            }

            // scroll to window top
            $("html, body").animate({
                scrollTop: 0
            }, 500);
        },

        /* Update progress bar
         * ============================= */
        _updateProgress: function(prgs) {
            $('#progress_info').text(Math.round(100 * prgs) + '%');
            $('#progress_bar > em').css('width', (prgs * 100) + '%');
        }

    }); // survey filler

});