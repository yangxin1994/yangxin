//=require ./base
//=require ../models/survey
//=require ./fillers_mobile
//=require ui/express_widgets/od_popup
//=require ui/plugins/od_button_text
//=require jquery.scrollTo
//=require jquery.cookie

//=require ../templates/survey_filler_qs_mobile
//=require ../templates/survey_filler_submit_mobile
//=require ../templates/survey_filler_end_money_mobile
//=require ../templates/survey_filler_end_money_finish_mobile
//=require ../templates/survey_filler_end_free_mobile
//=require ../templates/survey_filler_end_point_finish_mobile
//=require ../templates/survey_filler_end_lottery_mobile
//=require ../templates/survey_filler_redo_mobile
//=require ../templates/survey_filler_reject_mobile

$(function(){
	/* Survey filer
	 * options:
	 *    answer_id: string, if null, the user has not started answer the survey
	 *		data: the init data for the filler
	 *		is_preview: bool, 
	 *		preview_key: string, 
	 *		reward: object,
	 *		signin: bool
	 * =========================== */
	quill.quillClass('quill.views.SurveyFiller', quill.views.Base, {

		_initialize: function() {
			if(this.options.reward == null)
				this.options.reward = {reward_type : 0};
		},

		_uri: function(path) {
			return '/answers/' + this.options.answer_id + (path || '') + '.json';
		},

		_error: function(msg) {
			$.od.odPopup({content: msg});
		},		


		_spread: function() {
			if(this.options.spread_point <= 0) return;
			$.od.odShare({
				point: this.options.spread_point,
				survey_title: this.model.get('title'),
				scheme_id: this.options.reward.id,
				images: ""	//TODO: images for lottery
			});
		},

		_render: function() {
			// Setup page
			this._setup(this.options.data);
		},

		_share:function(){
			$('#f_body').append(window.spread_dom);

			$('#f_body').click(function(e){
				if($(e.target).attr('id') !== 'socal_share'){
					$('.spread').animate({"top" : "-2000px"}, 'fast');
				}
			})

			$('#socal_share').click($.proxy(function() {
				if(this.options.signin){
					var s_icon_height = $('.s_icon').css('height');
					var share_top_height = $('.share_top').css('height');
					var top = parseInt(s_icon_height,10) / 2 - parseInt(share_top_height,10) / 2 ; 
					$('.share_top').css('top',top)

					$('.spread').animate({"top" : "0px"}, 'fast');
					var href = window.location.href
					_.each(['SinaWeibo', 'TencentWeibo', 'Renren', 'Douban', 'QQSpace', 
						'Kaixin001', 'Diandian', 'Gmail', 'Fetion'], function(v) {
						$('.spread .icon-' + v).click(function() {
							$.social['shareTo' + v](href, '亲，帮忙填写一份问卷哦~');
						});
					});								
				}else{
					ref = window.location.href
					location.href = '/account/sign_in?ref=' + ref;
				} 
			}, this));

			$('.spread').click(function(){
				$('.spread').animate({"top" : "-2000px"}, 'fast');
			})			
		},

		_set_reward:function(){
			$.postJSON(this._uri('/start_bind'), function(retval){}) 
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
			if(data == null || !data.success) {
				$.od.odPopup({content: '加载问题出错，请刷新页面重试。'});
				return;
			}
			// If success, setup page		
			$('#f_body').empty();
			var value = data.value;		
			value.answer_status == 1 ? $('#progress').show() : $('#progress').hide();// show or hide the progress bar
			if(value.answer_status == 1){
				// answer_status: 1（正在回答）
				var questions = value.questions, answers = value.answers, total_count = value.question_number, 
					index = value.answer_index, time = value.estimate_answer_time, redo_count = value.repeat_time;				

				if(questions.length == 0) {
					//该页显示问题数量为0，此时表示题已经加载完最后一道，应该做提交操作
					this._updateProgress(1);//标识答题进度为100%
					//渲染提交页面
					this.hbs({
						remind: redo_count > 0,
						allow_pageup: this.model.get('style_setting').allow_pageup,
						show_restart: this.options.is_preview
					}, 'survey_filler_submit_mobile').appendTo($('#f_body'));

					// set prev and next button event
					var check_btn = $('#check_btn'), submit_btn = $('#submit_btn');						

					// check answer from page one when click on check button
					check_btn.click($.proxy(function() {
						$.util.disable(check_btn, submit_btn);
						this.load_questions(-1, true);
					}, this));

					// submit answer when click on submit button
					submit_btn.click($.proxy(function() {
						$.util.disable(check_btn, submit_btn);
						submit_btn.text('正在提交...');
						$.postJSON(this._uri('/finish'), $.proxy(function(retval) {
							this.load_questions(-1, true);
						}, this));
					}, this));
				}else{
					this._updateProgress(index / total_count);
					// setup survey filler container
					this.hbs({
						remind: redo_count > 0,
						allow_pageup: this.model.get('style_setting').allow_pageup,
						show_restart: this.options.is_preview,
						welcome: this.model.get('welcome')
					}, 'survey_filler_qs_mobile').appendTo($('#f_body'));
	
					// Setup questions fillers
					var idx = index;
					for (var i = 0; i < questions.length; i++) {
						// model is a special question
						var model = this.model.setQuestionModel(questions[i]);
						if(quill.helpers.QuestionType.getName(model.get('question_type')) == 'Paragraph') idx --;
						var filler = new quill.views.fillersMobile[quill.helpers.QuestionType.getName(questions[i].question_type)]({
							model: model,
							index: idx++
						}).appendTo($('#questions_con'));
						filler.setAnswer(answers[model.id]);
					};

					if(index > 0)
						$('#questions_con .q-filler:eq(0)').addClass('top');
					$('#questions_con .q-filler:last').addClass('bottom');
					if(!this.model.get('style_setting').has_question_number)
						$('#questions_con .q-idx').hide();	// hide q-idx if necessary

					// Setup next and previous buttons
					var next_btn = $('#next_btn'), prev_btn = $('#prev_btn');
					// Disable next button for some time (don't disable it for allow_pageup==true survey, or previewing)
					var has_not_empty_answer = (_.find(answers || [], function(a) { return a != null; }) != null);
					if(!has_not_empty_answer && !this.options.is_preview && prev_btn.length > 0) {
						$.util.disable(next_btn);
						var old_text = next_btn.text();
						function _update_btn() {
							if(time == 0) {
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
					next_btn.click($.proxy(function() {
						$.util.disable(next_btn, prev_btn);
						// submit question answers
						// 1. get answers
						var answer_info = {}, error_filler = null;
						$('.q-filler').each(function(i, v) {
							var filler = $(this).data('view');
							var result = filler.getAnswer();
							if(!error_filler && result.error) error_filler = filler;
							answer_info[filler.model.id] = result.answer;
						});
						if(error_filler) {
							// 2. if there is any illegal answer, alert
							$(window).scrollTo(error_filler.$el, 500, { offset: {top: -60} });
							$.util.enable(prev_btn, next_btn);
						} else {
							// 3. submit answers
							next_btn.text('正在提交答案...');
							$.util.disable(prev_btn, next_btn);
							$.postJSON(this._uri('/update_for_mobile'), { answer_content: answer_info }, $.proxy(function(retval) {
								if(retval && retval.success) {
									next_btn.text('正在加载问题...');
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
						prev_btn.text('正在加载上一页问题...');
						this.load_questions((questions.length > 0) ? questions[0]['_id'] : -1, false);
					}, this));
					if(index == 0) prev_btn.hide();									
				}
			}else if(value.answer_status == 4 || value.answer_status == 8 || value.answer_status == 32){		
				// answer_status: 4（待审核），8（等待代理审核），32（完成）
				if(this.options.reward.reward_scheme_type == 0) {
					this.hbs({
						spreadable: this.options.spread_point > 0,
						spread_point: this.options.spread_point
					}, 'survey_filler_end_free_mobile').appendTo('#f_body');

					this._share();
					$('#close_btn').click($.proxy(function() { location.href = '/'; }, this));
				} else if(this.options.reward.reward_scheme_type == 1) {
					if(value.order_id == null){
						this.hbs({}, 'survey_filler_end_money_mobile').appendTo($('#f_body'));
						$('.s_type select').children('option[value="zhifubao"]').text('为您支付宝付款￥' + this.options.reward.reward_money + '元')
						$('.s_type select').children('option[value="chongzhi"]').text('为您手机充值￥' + this.options.reward.reward_money + '元')

						var next_btn = $('#rew_next'),check_btn = $('#check_btn');				
	
	
						function show_zhifubao_ipt(){
							$('#zhifubao').show();
							$('#chongzhi').hide();
						}
	
						function show_chongzhi_ipt(){
							$('#chongzhi').show();
							$('#zhifubao').hide();
						}
	
						function show_reward_account(tp){
							if(tp == 'zhifubao'){
								show_zhifubao_ipt();
							}else{
								show_chongzhi_ipt();
							}
						}					

						var account_ipt = $('.rew_ipt input').filter(':visible');

	
						var rew_type = $('.s_type select').val();
						show_reward_account(rew_type)
						$('.s_type select').change($.proxy(function(){
							account_ipt = $('.rew_ipt input').filter(':visible');
							var rew_type = $('.s_type select').val();
							show_reward_account(rew_type)
						},this))
	
						account_ipt.focus(function(){
							$(this).removeClass('error');
						})					

						next_btn.click($.proxy(function() {
							account_ipt = $('.rew_ipt input').filter(':visible');
							var award_type = account_ipt.attr('name');
							var acc = $.trim(account_ipt.val());
							if(award_type == 'chongzhi'){
								confirm_acc =  $.trim($('input[name="confirm_chongzhi"]').val());
								console.log(confirm_acc)
								if(!$.regex.isMobile(acc)){
									account_ipt.addClass('error');
									this._error('请输入正确手机号');
									return false;
								}else if(acc !== confirm_acc){
									this._error('手机号不一致');
									return false;
								}
							}else{
								confirm_acc = $.trim($('input[name="confirm_zhifubao"]').val());
								if(!$.regex.isMobile(acc) && !$.regex.isEmail(acc)){
									account_ipt.addClass('error');
									this._error('请输入手机号或邮箱');
									return false;	
								}else if(acc !== confirm_acc){
									this._error('账户输入不一致');
									return false;										
								}
							}


							var infos = {
								chongzhi: {error__12: '此手机号已经参加过本次调研，不能重复充值。', error__15: '此手机号已参加过' + window.config.corp_name + '其他调研，无法申请本热点调查奖励。',
									ipt_value: this.options.mobile },
								zhifubao: {error__12: '此支付宝账号已经参加过本次调研，不能重复转账。', error__15: '此支付宝账号已参加过' + window.config.corp_name + '其他调研，无法申请本热点调查奖励。',
									ipt_value: this.options.email },
								jifenbao: {error__12: '此集分宝账号已经参加过本次调研，不能重复转账。', error__15: '此集分宝账号已参加过' + window.config.corp_name + '其他调研，无法申请本热点调查奖励。',
									ipt_value: this.options.email }
							}

							next_btn.odButtonText({text: '正在提交订单...'});
							$.util.disable(next_btn, account_ipt);

							$.postJSON(this._uri('/select_reward_for_mobile'), {
								type: award_type,
								account: acc
							}, $.proxy(function(retval) {
								if(retval.success) {								
									location.reload(true);
								} else {
									next_btn.odButtonText('restore');
									$.util.enable(next_btn, account_ipt);
									var error_msg = ((retval.value != null) ? infos[award_type][retval.value.error_code] : null);
									if(error_msg != null) {
										this._error(error_msg);
									}else{
										this._error('订单提交失败，请刷新页面重试');										}
								}
							}, this));
						}, this));
					}else{
						this.hbs({
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
							show_subscribe: !this.options.binded
						}, 'survey_filler_end_money_finish_mobile').appendTo('#f_body');

						this._share();

						if(!this.options.signin){
							this._set_reward();
						}	

						$('#get_order').click($.proxy(function(){
							$.util.disable($('#get_order').text('正在跳转...'));
							if(!this.options.signin){
								location.href = '/account/sign_in?ref=/users/orders'; 
							}else{
								location.href = '/users/orders'; 
							}						
						},this))	
						
					}
				} else if(this.options.reward.reward_scheme_type == 2) {
					this.hbs({
						reward_point: this.options.reward.reward_point,
						signin: this.options.signin,
						spreadable: this.options.spread_point > 0,
						spread_point: this.options.spread_point
					},'survey_filler_end_point_finish_mobile').appendTo('#f_body');


					if(!this.options.signin){
						this._set_reward();
					}

					this._share();	
					$('.rew_next').click($.proxy(function(){
						$.util.disable($('.rew_next').text('正在跳转...'));
						if(!this.options.signin){
							location.href = '/account/sign_in?ref=/users/points'; 
						}else{
							location.href = '/users/points'; 
						}						
					},this))		
				} else if(this.options.reward.reward_scheme_type == 3) {
					this.hbs({
						spread_point:this.options.spread_point
					}, 'survey_filler_end_lottery_mobile').appendTo('#f_body');
					$('#rew_next').click($.proxy(function() { location.href = '/lotteries/' + this.options.answer_id; }, this));
					this._share();
				}
			}else if (value.answer_status == 16){
				// 重答
				this.hbs({}, 'survey_filler_redo_mobile').appendTo($('#f_body'));
				var redo_btn = $('#redo_btn').click($.proxy(function() {
					redo_btn.attr('disabled', 'disabled').text('正在准备重新答题...');
					$.postJSON(this._uri('/clear'), $.proxy(function(retval) {
						this.load_questions(-1, true);
					}, this));
				}, this));				
			}else if(value.answer_status == 2){
				// 被拒绝
				// reject 1（配额已满），2（未通过自动质控），4（未通过人工质控），8（甄别题）或者16（超时）

				this.hbs({
					quality: (value.answer_reject_type == 2),
					review_failed: (value[1] == 2),
					filter: (value.answer_reject_type == 1 || value.answer_reject_type == 8),
					timeout: (value.answer_reject_type == 16),
					review_failed: (value.answer_reject_type == 4),
					reject_reason: value.answer_audit_message,
					show_restart: this.options.is_preview,
					spreadable: this.options.spread_point > 0,
					spread_point: this.options.spread_point					
				}, 'survey_filler_reject_mobile').appendTo('#f_body');
				$('#start_spread').click($.proxy(function() { this._spread(); }, this));
				$('#close_btn').click($.proxy(function() { location.href = this._redirect_link; }, this));				
			} 


			$('#restart_btn').click($.proxy(function() {
				if($('#restart_btn').attr("disabled") == 'disabled')
					return;
				$('#restart_btn').text("加载中...");
				$.util.disable($('#restart_btn'));
				var callback = $.proxy(function(retval) {
					if(retval.success) {
						if(this.options.is_preview)
							location.href = '/p/' + this.options.reward.id + '?m=true';
					} else
						$.od.odPopup({content: '操作失败，请刷新页面重试。'});
				}, this);

				if(this.options.is_preview) {
					$.deleteJSON(this._uri('/destroy_preview'), callback);
				}
			}, this));

			var minHeight = $(window).height() - 114;
			$('.page').css('minHeight', minHeight);

			// scroll to window top
			$("html, body").animate({ scrollTop: 0 }, 500);			
		},

		/* Update progress bar
		 * ============================= */
		_updateProgress: function(prgs) {
			$('#progress_txt').text(Math.round(100 * prgs) + '%');
			$('#progress > em').css('width', (prgs * 100) + '%');
		}

	}); // survey filler

});
