//=require ./base
//=require ../models/survey
//=require ./fillers_mobile
//=require ui/widgets/od_popup
//=require jquery.scrollTo
//=require ../templates/survey_filler_qs_mobile
//=require ../templates/survey_filler_submit_mobile
//=require ../templates/survey_filler_redo_mobile
//=require ../templates/survey_filler_review_mobile
//=require ../templates/survey_filler_finish_mobile
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

		_render: function() {
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
			if(data == null || !data.success) {
				$.od.odPopup({content: '加载问题出错，请刷新页面重试。'});
				return;
			}
			// If success, setup page		
			$('#f_body').empty();
			var value = data.value;
			if(value.length == 3) {
				// answer status [answer.status, answer.reject_type, answer.audit_message]
				// value[0]: 0（正在回答），1（被拒绝），2（待审核），3（pass）或者4（重填）
				if(value[0] == 4) {
					// redo
					this.hbs({
					}, 'survey_filler_redo_mobile').appendTo($('#f_body'));
					var redo_btn = $('#redo_btn').click($.proxy(function() {
						redo_btn.attr('disabled', 'disabled').text('正在准备重新答题...');
						$.postJSON(this._uri('/clear'), $.proxy(function(retval) {
							this.load_questions(-1, true);
						}, this));
					}, this));					
				} else {
					if(value[0] == 2 || value[0] == 3) {
						// 2、review 3 finish
						this.hbs({
							reward_point: this.options.reward.reward_type == 2,
							point: this.options.reward.point,
							reward_lottery: this.options.reward.reward_type == 1,
							lottery_id: this.options.reward.lottery_id, 
							lottery_title: this.options.reward.lottery_title,
							signin: this.options.signin,
							show_restart: this.options.is_preview || this.model.get('style_setting').allow_pageup
						}, (value[0] == 2) ? 'survey_filler_review_mobile' : 'survey_filler_finish_mobile').appendTo('#f_body');											
					} else {
						// reject 0（配额已满），1（未通过自动质控），2（未通过人工质控），3（甄别题）或者4（超时）
						this.hbs({
							full: (value[1] == 0),
							quality: (value[1] == 1),
							review_failed: (value[1] == 2),
							filter: (value[1] == 3),
							timeout: (value[1] == 4),
							reject_reason: value[2],
							show_restart: this.options.is_preview || this.model.get('style_setting').allow_pageup
						}, 'survey_filler_reject_mobile').appendTo('#f_body');
					};

					var close_btn = $('#close_btn').click($.proxy(function() {
						var link = this.model.get('style_setting').redirect_link;
						if($.regex.isUrl(link)) {
							link = link.toLowerCase();
							if(link.indexOf('http') != 0)
								link = 'http://' + link;
						} else {
							link = '/';
						}
						location.href = link;
					}, this));

					// update progress
					this._updateProgress(1);						
					
					// hide restart button when is not previewing
					if(!this.options.is_preview)
						$('#restart_btn').hide();

					// add spread dom
					$('#sf_main').append(window.spread_dom);				
				}
			} else {
				// setup questions
				var questions = value[0], answers = value[1], total_count = value[2], 
					index = value[3], time = value[4], redo_count = value[5];

				// setup question or submit page
				if(questions.length == 0) {
					// Question.length == 0. Should submit answer

					// update progress
					this._updateProgress(1);

					// setup page
					this.hbs({
						remind: redo_count > 0,
						allow_pageup: this.model.get('style_setting').allow_pageup,
						show_restart: this.options.is_preview || this.model.get('style_setting').allow_pageup
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
											
				} else {
					// update progress
					this._updateProgress(index / total_count);

					// setup survey filler container
					this.hbs({
						remind: redo_count > 0,
						allow_pageup: this.model.get('style_setting').allow_pageup,
						show_restart: this.options.is_preview || this.model.get('style_setting').allow_pageup
					}, 'survey_filler_qs_mobile').appendTo($('#f_body'));
	
					// Setup questions fillers
					var idx = index;
					for (var i = 0; i < questions.length; i++) {
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
						if(next_btn.attr("disabled") == 'disabled')
							return;
						$.util.disable(next_btn, prev_btn);
						// submit question answers
						// 1. get answers
						var answer_content = {}, error_filler = null;
						$('#questions_con .q-filler').each(function(i, v) {
							var filler = $(this).data('view');
							var result = filler.getAnswer();
							if(!error_filler && result.error) error_filler = filler;
							answer_content[filler.model.id] = result.answer;
						});
						if(error_filler) {
							// 2. if there is any illegal answer, alert
							$(window).scrollTo(error_filler.$el, 500, { offset: {top: -20} });
							$.util.enable(prev_btn, next_btn);
						} else {
							// 3. submit answers
							next_btn.text('正在提交...');
							$.util.disable(prev_btn, next_btn);
							$.putJSON(this._uri(), { answer_content: answer_content }, $.proxy(function(retval) {
								if(retval && retval.success) {
									next_btn.text('加载中...');
									this.load_questions((questions.length > 0) ? 
										questions[questions.length - 1]['_id'] : -1, true);
								} else {
									location.reload(true);
								}
							}, this));
						}
					}, this));

					prev_btn.click($.proxy(function() {
						if(prev_btn.attr("disabled") == 'disabled')
							return;					
						$.util.disable(next_btn, prev_btn);
						this.load_questions((questions.length > 0) ? questions[0]['_id'] : -1, false);
					}, this));
					if(index == 0) prev_btn.hide();

				};							
			};
			// Set restart answer button event
			$('#restart_btn').click($.proxy(function() {
				if($('#restart_btn').attr("disabled") == 'disabled')
					return;
				$('#restart_btn').text("加载中...");
				$.util.disable($('#restart_btn'));
				var callback = $.proxy(function(retval) {
					if(retval.success) {
						if(this.options.is_preview)
							location.href = '/p/' + this.model.id + '?m=true';
						else
							location.href = '/s/' + this.model.id + '?m=true';
					} else
						$.od.odPopup({content: '操作失败，请刷新页面重试。'});
				}, this);
				if(this.options.is_preview) {
					$.deleteJSON(this._uri('/destroy_preview'), callback);
				} else {
					$.postJSON(this._uri('/clear'), callback);
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
			$('#progress_txt').text((Math.round(10000 * prgs) / 100) + '%');
			$('#progress > em').css('width', (prgs * 100) + '%');
		}

	}); // survey filler

});
