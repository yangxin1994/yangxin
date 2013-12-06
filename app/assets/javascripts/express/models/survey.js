//=require ./base
//=require ./questions

/* ================================
 * Survey model
 * ================================ */

$(function(){

	/* Survey model
	 * =========================== */
	quill.quillClass('quill.models.Survey', quill.models.Base, {
	
		/* Base properties for question
		 * =========================== */
		_defaults: {
			_id: null,
			user_id: null,
			title: '未命名',
			subtitle: null,
			welcome: null,
			closing: null,
			header: '欢迎参加调查',
			footer: '技术支持：',
			description: null,
			created_at: new Date(),
			publish_status: 0,
			logic_control: [],
			pages: [{name: 'new page', questions:[]}],
			style_setting: null,
			quality_control_setting: {},
			quota: {},
			quota_stats: {}
		},
		
		/* initialize model. set _question_type_label.
		 * =========================== */
		_initialize: function() {
			// ensure that pages is not null
			if (this.get("pages") == null || this.get('pages').length == 0) {
			  this.set({"pages": this.defaults().pages});
			}
		},
		
		/* Check whether the survey is published
		 * =========================== */
		// isPublished: function() {
		// 	// 1 closed 2 reviewing 4 paused 8 published
		// 	return this.get('publish_status') == 8;
		// },

		/* ==================================================
		 * common methods
		 * ================================================== */

		/* construct uri
		 * =========================== */
		_uri: function(name) {
			return '/e/questionaires/' + this.id + (name || '') + '.json'
		},

		/* ==================================================
		 * Survey properties
		 * ================================================== */
		updateTitle: function(title, callback) {
			callback = $.ensureCallback(callback);
			if(!title || title == this.get('title')) {
				callback.success();
				return;
			}
			$.putJSON(this._uri('/property'), {
				properties: { title: title }
			}, $.proxy(function(retval) {
				if(retval.success) {
					this.set('title', title);
					callback.success();
				} else {
					callback.error(retval.value);
				}
			}, this));
		},

		/* ==================================================
		 * Page related actions
		 * ================================================== */

		/* Count the pages
		 * =========================== */
		pageCount: function() {
			return this.get('pages').length;
		},

		/* Split one page before the question of 'before_question_id' 
		 * =========================== */
		splitPage: function (before_question_id, callback) {
			var pos = this.findQuestionPosition(before_question_id);
			if(!pos) return;
			$.putJSON(this._uri('/pages/' + pos.pageIndex + '/split'), {
				before_question_id: before_question_id
			}, $.proxy(function(retval) {
				callback = $.ensureCallback(callback);
				if(retval.success) {
					//1. update pages structure
					var ps = this.get('pages');
					ps[pos.pageIndex] = retval.value[0];
					ps.splice(pos.pageIndex + 1, 0, retval.value[1]);
					callback.success(pos);
				} else {
					callback.error(retval.value);
				}
			}, this));
		},

		/* Combine one page with its next page
		 * =========================== */
		combinePages: function (page_index, callback) {
			$.putJSON(this._uri('/pages/' + page_index + '/combine'), {}, $.proxy(function(retval) {
				callback = $.ensureCallback(callback);
				if(retval.success) {
					//1. update pages structure
					var ps = this.get('pages');
					if(page_index + 1 < ps.length) {
						ps[page_index].questions = ps[page_index].questions.concat(ps[page_index + 1].questions);
						ps.splice(page_index + 1, 1);
					}
					callback.success(page_index);
				} else {
					callback.error(retval.value);
				}
			}, this));
		},

		/* ==================================================
		 * Question related actions
		 * ================================================== */

		_question_models: {},		// survey model should keep question models for futher manipulations

		/* Generate a question model and put it into _quesion_models
		 * =========================== */
		setQuestionModel: function(question_or_model) {
			if(question_or_model.__isModel) {
				this._question_models[question_or_model.id] = question_or_model;
				return question_or_model;
			} else {
				// question_or_model.question_type = 0; hack for unfinished quesiton editors
				question_or_model._surveyModel = this;
				var m = new quill.models.questions[quill.helpers.QuestionType.getName(question_or_model.question_type)](question_or_model);
				this._question_models[question_or_model._id] = m;
				return m;
			}
		},

		/* Find the position of a question
		 * =========================== */
		findQuestionPosition: function(model_or_id) {
			var id = model_or_id.__isModel ? model_or_id.id : model_or_id; 
			var ps = this.get('pages');
			var idx = 0;
			for (var i=0; i < ps.length; i++) {
				var p = ps[i];
				for (var k=0; k < p.questions.length; k++) {
					if(p.questions[k] == id) {
						return {pageIndex: i, questionIndex: k, index: idx};
					}
					idx++;
				};
			};
			return null;
		},

		/* Get one question model
		 * callback = function(question_model) {}
		 */
		getQuestion: function(qid, callback) {
			callback = $.ensureCallback(callback);
			if(this._question_models[qid]) {
				callback.success(this._question_models[qid]);
			} else {
				$.getJSON(this._uri('/questions/' + qid), $.proxy(function(retval) {
					if(retval.success) {
						callback.success(this.setQuestionModel(retval.value));
					} else {
						callback.error(retval.value);
					}
				}, this));
			}
		},

		/* Get questions in one page
		 * callback = function(question_models) {}
		 */
		getQuestions: function(page_index, callback) {
			callback = $.ensureCallback(callback);
			var ps = this.get('pages');
			if(page_index < 0 || page_index >= ps.length) {
				callback.error();
			}
			var qids = ps[page_index].questions;
			if(!qids || qids.length == 0) {
				callback.success([]);
			} else {
				$.getJSON(this._uri('/pages/' + page_index), $.proxy(function(retval) {
					if(retval.success) {
						var qs = retval.value.questions;
						var models = [];
						for (var i = 0; i < qs.length; i++) {
							models.push(this.setQuestionModel(qs[i]));
						};
						callback.success(models);
					} else {
						callback.error(retval.value);
					}
				}, this));
			}
		},

		/* Add question into page of 'page_index' after question of 'after_question_id'
		 * If 'after_question_id' is -1, add question at the last of the page
		 * If 'after_question_id' is 0, add question at the begining of the page
		 * If page_index is illegal, add a new page to the end of the survey and add the question into the new page
		 * =========================== */
		addQuestion: function(page_index, after_question_id, question_type, callback) {
			var type_value = quill.helpers.QuestionType.getValue(question_type);
			if(type_value < 0) {
				callback.error();
				return;
			}
			$.postJSON(this._uri('/questions'), {
				page_index: page_index,
				after_question_id: after_question_id,
				question_type: type_value
			}, $.proxy(function(retval) {
				callback = $.ensureCallback(callback);
				if(retval.success) {
					// 1. update question models
					var new_q_model = this.setQuestionModel(retval.value);
					// 2. update survey page structrue
					var qid = retval.value._id;
					var ps = this.get('pages');
					if(page_index < 0 || page_index >= ps.length) {
						// page index is illegal, add a new page
						ps.push({name: 'new page', questions:[qid]});
					} else {
						var p = ps[page_index];
						if(after_question_id == -1) {
							p.questions.splice(p.questions.length, 0, qid);
						} else if(after_question_id == 0) {
							p.questions.splice(0, 0, qid);
						} else {
							for (var i = 0; i < p.questions.length; i++) {
								if(p.questions[i] == after_question_id) {
									p.questions.splice(i+1, 0, qid);
									break;
								}
							};
						}
					}
					// 3. call callback
					callback.success(qid);
				} else {
					callback.error(retval.value);
				}
			}, this));
		},

		/* Delete a question from the survey
		 * =========================== */
		removeQuestion: function(question_id, callback) {
			var pos = this.findQuestionPosition(question_id);
			if(!pos) return;
			$.deleteJSON(this._uri('/questions/' + question_id), {}, $.proxy(function(retval) {
				callback = $.ensureCallback(callback);
				if(retval.success) {
					// 1. remove qid from pages
					this.get('pages')[pos.pageIndex].questions.splice(pos.questionIndex, 1);
					// 2. remove question model from model cache
					delete this._question_models[question_id];
					// 3. call callback
					callback.success();
				} else {
					callback.error(retval.value);
				}
			}, this));
		},

		/* Move a question after after_question_id
		 * if after_question_id is 0, move question_id to the begining of page_index
		 * if page_index is illegal, add a new page to the end of the survey and move question_id to the new page
		 * =========================== */
		moveQuestion: function(question_id, after_question_id, page_index, callback) {
			$.putJSON(this._uri('/questions/' + question_id + '/move'), {
				after_question_id: after_question_id,
				page_index: page_index
			}, $.proxy(function(retval) {
				callback = $.ensureCallback(callback);
				if(retval.success) {
					// 1. udate survey structure
					var ps = this.get('pages');
					var pos = this.findQuestionPosition(question_id);
					// remove old question
					ps[pos.pageIndex].questions.splice(pos.questionIndex, 1);
					if(page_index < 0 || page_index >= ps.length) {
						// page index is illegal, add a new page
						ps.push({name: 'new page', questions:[question_id]});
					} else {
						if(after_question_id == 0) {
							ps[page_index].questions.splice(0, 0, question_id);
						} else {
							var after_pos = this.findQuestionPosition(after_question_id);
							ps[after_pos.pageIndex].questions.splice(after_pos.questionIndex + 1, 0, question_id);
						}
					}
					// 3. call callback
					callback.success();
				} else {
					callback.error(retval.value);
				}
			}, this));
		}

	});	// survey model

});