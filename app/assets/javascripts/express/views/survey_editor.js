//=require jquery.viewport
//=require jquery.scrollTo
//=require ./base
//=require ./designers
//=require ../templates/adding_question
//=require ../templates/page_index
//=require ../templates/survey_editor
//=require ../models/survey
//=require ui/plugins/od_enter

$(function(){
	
	/* Survey editor
	 * =========================== */
	quill.quillClass('quill.views.SurveyEditor', quill.views.Base, {

		_initialize: function() { },

		_is_ready: false,

		_renderBasic: function() {

		},

		_render: function() {
			this.replaceElement(this.hbs(this.model.toJSON()));

			/* edit survey title
			 * =============================== */
			var save_title = $.proxy(function() {
				this.$('.s-title .s-title-con input').attr('disabled', 'disabled');
				this.$('.s-title .s-title-con button').attr('disabled', 'disabled');
				this.model.updateTitle(this.$('.s-title-con input').val(), {
					success: $.proxy(function() {
						this.$('.s-title .s-title-preview').text(this.model.get('title'));
					}, this), 
					after: $.proxy(function() {
						this.$('.s-title .s-title-con input').attr('disabled', null);
						this.$('.s-title .s-title-con button').attr('disabled', null);
						this.$('.s-title').removeClass('active');
					}, this)
				});
			}, this);
			var start_edit_title = $.proxy(function() {
				if(this._current_designer)
					this._current_designer.openRender();
 				this.$('.s-title').addClass('active');
 				this.$('.s-title-con input').focus();
 				$(document).one('click', save_title);
 			}, this);
			var btn = $.od.odIconButtons({
				buttons:	[{
		 			name: 'edit',
		 			info: '编辑问卷标题',
		 			click: start_edit_title
		 		}]
			}).appendTo(this.$('.s-title .t-btns'));
			this.$('.s-title').click(function(e) {e.stopPropagation()}).dblclick(start_edit_title);
			this.$('.s-title .s-title-con input').odEnter({ enter: save_title });
			this.$('.s-title .s-title-con button.ok').mousedown(save_title);
			this.$('.s-title .s-title-con button.cancel').click($.proxy(function() {
				this.$('.s-title').removeClass('active');
			}, this));

			/* event for buttons in no-question contain
			 * =============================== */
			this.$('.s-no-question button').click($.proxy(function(e) {
				this.addQuestionAuto($(e.target).attr('t'));
			}, this));

			/* render pages one by one
			 * =============================== */
			var _render_page = $.proxy(function(page_index) {
				if(page_index >= this.model.pageCount()) {
					this.refreshPageIndexes();
					this.refreshQuestionIndexes();
					this._is_ready = true;
					return;
				}

				// get one page questions and render
				// this._msg('loading page ' + page_index);
				this.model.getQuestions(page_index, {

					success: $.proxy(function(q_models) {
						// 1. render one page questions
						var qids = this.model.get('pages')[page_index].questions;
						var _render = $.proxy(function(question_index) {
							if(question_index >= qids.length)
								return;
							this.renderQuestion(qids[question_index], function() {
								_render(question_index + 1);
							});
						}, this);
						_render(0);
						// 2. render page index
						this._newPageIndex(page_index).appendTo(this.$('.s-pages'));
						// 3. render next page questions
						_render_page(page_index + 1);
					}, this), 

					error: $.proxy(function(err) {
						// this._msg('loading page ' + page_index + ' error!');
					}, this)

				});
			}, this);
			_render_page(0);	// start to render pages

			// make questions sortable
			this.$('.s-pages').sortable({
				cancel: ".page-index, .drop-question",
				stop: $.proxy(function(event, ui) {
					var qid = ui.item.data('view').model.id;
					var after_question_id = 0;
					var prev_dom = ui.item.prev();
					if(prev_dom.hasClass('q-designer')) {
						after_question_id = prev_dom.data('view').model.id;
					} 
					var page_index = ui.item.prevAll(".page-index").length;
					this.moveQuestion(qid, after_question_id, page_index);
				}, this)
			});

		},

		/* ==================================================
		 * common methods
		 * ================================================== */

		/* Show message
		 * =========================== */
		// _msg: function(msg) {
		// 	//TODO: change
		// 	$('#msg').text(msg);
		// 	if(!msg) { $('#msg').hide(); } else { $('#msg').show(); }
		// },

		/* ==================================================
		 * Page related methods
		 * ================================================== */

		/* Split one page into two pages
		 * =========================== */
		splitPage: function(before_question_id) {
			this._newPageIndex(0).insertBefore(this.findQDesigner(before_question_id).$el);
			this.refreshPageIndexes();
			this.model.splitPage(before_question_id, {
				success: function() {},
				error: function() {}
			});
		},

		/* Combine two pages into one
		 * =========================== */
		combinePages: function(page_index) {
			this.findPageIndexDom(page_index).remove();
			this.refreshPageIndexes();
			this.model.combinePages(page_index, {
				success: function() {},
				error: function() {}
			});
		},

		/* New a page index
		 * =========================== */
		_newPageIndex: function(page_index) {
			var pidx = this.hbs(page_index + 1, 'page_index');

			// get page position
			var _page_pos = $.proxy(function() {
				var idxes = this.$('.page-index');
				var idx = idxes.index(pidx);
				var legal = (idx < idxes.length - 1);
				return {
					total: idxes.length,
					index: idx,
					legal: idx < idxes.length - 1
				}
			}, this);

			$('.cancel-page', pidx).hide();
			pidx.hover($.proxy(function() {
				if(!_page_pos().legal) return;
				$('.page-label', pidx).hide();
				$('.cancel-page', pidx).show();
			}, this), function() {
				if(!_page_pos().legal) return;
				$('.page-label', pidx).show();
				$('.cancel-page', pidx).hide();
			});

			// combine pages when clicking on page index dom
			pidx.dblclick($.proxy(function() {
				var pos = _page_pos();
				if(!pos.legal) return;
				// start to combine
				this.combinePages(pos.index);
			}, this));

			// make page index droppable
			this.makeDroppable(pidx);

			return pidx;
		},

		/* Refresh the page indexes
		 * =========================== */
		refreshPageIndexes: function() {
			this.$('.page-index').each(function(i, v) {
				$('.page-label', this).text('第 ' + (i+1) + ' 页 结束');
			});
			this.$('.page-index').last().addClass('last');
		},

		/* Find a page index dom by index, or index by dom
		 * =========================== */
		findPageIndexDom: function(page_index) {
			return this.$('.page-index:eq(' + page_index + ')');
		},
		findPageDomIndex: function(page_dom) {
			return this.$('.page-index').index(page_dom);
		},

		/* ==================================================
		 * Question related methods
		 * ================================================== */

		_current_designer: null,

		/* find the question designer
		 * =========================== */
		findQDesigner: function(question_id) {
			return this.$('#q_designer_' + question_id).data('view');
		},

		/* Render one question and append it to its page_con
		 * =========================== */
		renderQuestion: function(qid, callback) {
			this.model.getQuestion(qid, $.proxy(function(q_model) {
				callback = $.ensureCallback(callback);
				var pos = this.model.findQuestionPosition(q_model);

				// setup question designer
				var designer = new quill.views.designers[quill.helpers.QuestionType.getName(q_model.get('question_type'))]({
					index: pos.index,
					model: q_model,
					remove: $.proxy(function(failed_callback) {
						// remove question from survey when click on designer's remove button
						this.removeQuestion(qid, failed_callback);
					}, this),
					saved: $.proxy(function(new_model) {
						// after the question is saved, we should update the question model cache
						this.model.setQuestionModel(new_model);
					}, this),
					pagination: $.proxy(function() {
						// add pagination before the designer
						this.splitPage(qid);
					}, this),
					onOpenRender: $.proxy(function() {
						if(this._current_designer == designer) {
							this._current_designer = null;
						}
						this.$('.s-pages').sortable('enable');
					}, this),
					onOpenEditor: $.proxy(function() {
						if(this._current_designer && this._current_designer != designer) {
							this._current_designer.openRender();
						}
						this._current_designer = designer;
						this.$('.s-pages').sortable('disable');
						// scroll to the designer
						if($('#q_designer_' + qid + ':in-viewport').length == 0) {
						// if($('#q_designer_' + qid + ':in-viewport').length == 0 ||
						// 	$('#q_designer_' + qid + ':above-the-top').length > 0) {
							$(window).scrollTo(designer.$el, 500, { offset: {top: -20} });
						}
					}, this)
				});

				// make designer droppable
				this.makeDroppable(designer.$el);

				// insert designer into page
				if(pos.questionIndex == 0) {
					if(pos.pageIndex == 0) {
						designer.$el.prependTo(this.$('.s-pages'));
					} else {
						designer.$el.insertAfter(this.findPageIndexDom(pos.pageIndex - 1));
					}
				} else {
					if(pos.pageIndex == 0) {
						designer.$el.insertAfter(
							this.$('.q-designer:eq(' + (pos.questionIndex - 1) + ')'));
					} else {
						designer.$el.insertAfter(
							this.$('.page-index:eq(' + (pos.pageIndex - 1) + ') ~ .q-designer:eq(' + (pos.questionIndex - 1) + ')'));
					}
				}

				callback.success();
			}, this));
		},

		/* Clean up and update highlight dom for adding question
		 * =========================== */
		makeDroppable: function(dom) {
			// make a designer or a page-index dom droppable in order to add question
			dom.droppable({
				over: $.proxy(function(event, ui) {
					if(!ui.helper.data('questionType')) return;
					ui.draggable.data("current-droppable", dom);
				}, this),
				out: $.proxy(function(event, ui) {
					if(!ui.helper.data('questionType')) return;
					if(ui.draggable.data('current-droppable') == dom)
						ui.draggable.removeData("current-droppable");
					this.cleanupHighlight();
				}, this),
				drop: $.proxy(function(event, ui) {
					if(!ui.helper.data('questionType')) return;
					var insert_after_dom = dom;
					if(dom.prev().hasClass('drop-question'))
						insert_after_dom = dom.prev().prev();
					var p_idx = 0, q_idx = 0;
					if(insert_after_dom.length != 0) {
						if(insert_after_dom.hasClass('q-designer')) {
							var pos = this.model.findQuestionPosition(insert_after_dom.data('view').model);
							p_idx = pos.pageIndex;
							q_idx = pos.questionIndex + 1;
						} else if(insert_after_dom.hasClass('page-index')) {
							p_idx = this.findPageDomIndex(insert_after_dom) + 1;
						}
					} 
					this.addQuestion(p_idx, q_idx, ui.helper.data('questionType'));
					this.cleanupHighlight();
				}, this)
			});

		},
		cleanupHighlight: function() {
			this.$('.drop-question').remove();
		},
		updateHighlight: function(q_designer_el, is_upper) {
			this.cleanupHighlight();
			if(is_upper) {
				$('<div class="drop-question" />').insertBefore(q_designer_el);
			} else {
				$('<div class="drop-question" />').insertAfter(q_designer_el);
			}
		},

		/* Start adding a question
		 * question_index: question index in page
		 * =========================== */
		addQuestion: function(page_index, question_index, question_type) {
			if(!this._is_ready) return;
			this._is_ready = false;
			// hide no-question con
			var no_question_hidden = !this.$('.s-no-question').is(':visible');
			this.$('.s-no-question').hide();

			var after_question_id = 0;

			// add waiting dom
			var adding_q_dom = this.hbs({paragraph: question_type=='Paragraph'}, 'adding_question');
			if(question_index == 0) {
				if(page_index == 0) {
					adding_q_dom.prependTo(this.$('.s-pages'));
				} else {
					adding_q_dom.insertAfter(this.findPageIndexDom(page_index - 1));
				}
			} else {
				after_question_id = this.model.get('pages')[page_index].questions[question_index - 1];
				adding_q_dom.insertAfter(this.findQDesigner(after_question_id).$el);
			}

			// start to add question
			var _start_to_add = $.proxy(function() {

				this.model.addQuestion(page_index, after_question_id, question_type, {
					
					before: $.proxy(function() {
						// show or hide no-question con
						no_question_hidden ? this.$('.s-no-question').hide() : this.$('.s-no-question').show();
						adding_q_dom.remove();
					}, this),

					success: $.proxy(function(new_qid) {
						// 1. if page_index is illegal, add new page
						if(page_index < 0 || page_index >= this.$('.page-index').length) {
							this._newPageIndex(this.$('.page-index').length).appendTo(this.$('.s-pages'));
							this.refreshPageIndexes();
						}
						// render question
						this.renderQuestion(new_qid, $.proxy(function() {
							this.refreshQuestionIndexes();
							// active question designer
							this.findQDesigner(new_qid).openEditor();
						}, this));
					}, this),

					after: $.proxy(function() {
						this._is_ready = true;
					}, this)

				});

			}, this);

			if($('.adding-question:in-viewport').length == 0) {
				$(window).scrollTo(adding_q_dom, 500, { 
					offset: {top: -20},
					onAfter: _start_to_add 
				});
			} else {
				_start_to_add();
			}

		},
		addQuestionAuto: function(question_type) {
			// add a question to the survey automatically
			// If _current_designer is not null, add the question after current designer
			// else add the question to the end of the survey and active it
			if(this._current_designer) {
				var pos = this.model.findQuestionPosition(this._current_designer.model);
				this.addQuestion(pos.pageIndex, pos.questionIndex + 1, question_type);
			} else {
				var ps = this.model.get('pages');
				//TODO: if ps.length = 0?
				this.addQuestion(ps.length - 1, ps[ps.length - 1].questions.length, question_type);
			}
		},

		/* Remove question
		 * =========================== */
		removeQuestion: function(question_id, failed_callback) {
			this.model.removeQuestion(question_id, {
				success: $.proxy(function() {
					this.findQDesigner(question_id).remove();
					this.refreshQuestionIndexes();
				}, this),

				error: failed_callback
			});
		},

		/* Move question
		 * TODO: waiting for finish 
		 * =========================== */
		moveQuestion: function(question_id, after_question_id, page_index) {
			this.model.moveQuestion(question_id, after_question_id, page_index, {
				success: $.proxy(function() {
					var q_designer_dom = this.findQDesigner(question_id).$el.detach();
					// 1. if page_index is illegal, add new page
					if(page_index < 0 || page_index >= this.$('.page-index').length) {
						this._newPageIndex(this.$('.page-index').length).appendTo(this.$('.s-pages'));
						this.refreshPageIndexes();
					}
					if(after_question_id == 0) {
						if(page_index == 0) {
							q_designer_dom.prependTo(this.$('.s-pages'));
						} else {
							q_designer_dom.insertAfter(this.findPageIndexDom(page_index - 1));
						}
					} else {
						q_designer_dom.insertAfter(this.findQDesigner(after_question_id).$el);
					}
					this.refreshQuestionIndexes();
				}, this),
				error: function() {}
			});
		},

		/* Refresh question indexes and refresh question backgrounds
		 * =========================== */
		refreshQuestionIndexes: function() {
			var index = 0;
			this.$('.q-designer').each(function(i, v) {
				var view = $(v).data('view');
				if(quill.helpers.QuestionType.getName(view.model.get('question_type')) == 'Paragraph')
					return;
				view.refreshIndex(index++);
			});
			if(this.$('.q-designer').length == 0) {
				this.$('.s-no-question').show();
			} else {
				this.$('.s-no-question').hide();
			}
		}

	});	// survey editor

});
