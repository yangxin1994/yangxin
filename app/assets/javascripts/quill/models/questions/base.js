//=require ../base
//=require ./modules

/* ================================
 * Base class for quill.models.questions
 * ================================ */

$(function(){

	/* Base question class
	 * =========================== */
	quill.quillClass('quill.models.questions.Base', quill.models.Base, {

		/* Base properties for question
		 * =========================== */
		_defaults: {
			_id: null,
			content: $.richtext.defaultValue('title'),
			note: null,
			question_type: 0,
			is_required: false,
			question_class: 0,	//0为普通问题，1为模板题，2为质控题
			reference_id: -1,
			issue: null,

			//temp parameters. Delete after initialize
			_surveyModel: null
		},

		/* Survey model
		 * =========================== */
		_surveyModel: null,

		/* issue of questions
		 * =========================== */
		issue: null,
		
		/* initialize model
		 * =========================== */
		_initialize: function() {
			// get question issue
			this.issue = $.extend({}, this.defaults().issue, this.get('issue'));
			this.set('issue', this.issue);

			this._surveyModel = this.get('_surveyModel');
			if(!this._surveyModel) {
				throw "survey model of question should not be null";
			}
			delete this.attributes._surveyModel;
		},

		/* clone a model
		 * =========================== */
		clone: function() {
			var json_obj = $.extend(true, {}, this.toJSON());	// deep clone!
			json_obj._surveyModel = this._surveyModel;	// REMEMBER to set survey model
			return new quill.models.questions[this._cn](json_obj);
		},

		/* url of question
		 * =========================== */
		url: function() {
			return '/questionaires/' + this._surveyModel.id + '/questions/' + this.id + '.json';
		},

		/* Save question
		 * =========================== */
		save: function(callback) {
			$.putJSON(this.url(), {
				question: this.toJSON()
			}, $.proxy(function(retval) {
				callback = $.ensureCallback(callback);
				if(retval.success) {
					callback.success(retval.value);
				} else {
					callback.error(retval.value);
				}
			}, this));
		},

		/* Serialize the model to array codes. 
		 * Deserialize the model from array codes.
		 * =========================== */
		serialize: function() {
			var retval = this._serialize();
			retval.splice(0, 0, this.get('content').text, '');
			return retval;
		},
		_serialize: function() {
			// to be overrided
			return [];
		},
		deserialize: function(codes) {
			if(!codes) return;
			codes = _.map(codes, function(str) {
				return $.trim(str);
			}).skipBlank();
			// set title
			if(codes.length == 0) return;
			var title = $.extend({}, this.get('content'));
			title.text = codes[0];
			this.set('content', title);
			// deserialize
			this._deserialize(codes.slice(1, codes.length));
		},
		_deserialize: function(codes) {
			// to be overrided
		},

		/* Get info
		 * =========================== */
		getInfo: function() {
			var info = this._getInfo();
			return info ? info : quill.helpers.QuestionType.getLabel(this.get('question_type'));
		},
		_getInfo: function() {
			// to be overrided
			return null;
		},

		/* Check whether a answer is legal
		 * =========================== */
		checkAnswer: function(answer) {
			if(answer == null)
				return '答案不能为空';
			else if(!this.get('is_required')) 
				return null;
			else
				return this._checkAnswer(answer);
		},
		_checkAnswer: function(answer) {
			throw 'You should override checkAnswer method!';
		}

	});

	/* setup a blank question model
	 * =========================== */
	quill.models.questions._setupBlank = function(type_name) {
		quill.quillClass('quill.models.questions.' + type_name.camel(true) + 'Blank', quill.models.questions.Base, {

			/* Default properties
			 * =========================== */
			_defaults: {
				issue: { }
			},
			
			_initialize: function() {
				$.extend(this, quill.modules[type_name](this, this.issue));
			}

		});
	};

});