//=require ../base
//=require ../../models/questions
//=require ../../templates/fillers_mobile/base
//=require ../../templates/fillers_mobile/media_preview
//=require jquery.colorbox

/* ================================
 * Namespace for oopsdata.views.fillersMobile
 * ================================ */

$(function(){
	
	/* Base question filler class
	 * options:
	 *   index: int
	 * =========================== */
	quill.quillClass('quill.views.fillersMobile.Base', quill.views.Base, {
		
		model_issue: null,

		_initialize: function() {
			this.model_issue = this.model.get('issue');
		},

		/* Render image/video/audio previews
		 * =============================== */
		renderMediaPreviews: function(parent, rich_value) {
			if(!parent) return;
			if(!rich_value) return null;
			_.each(['image', 'video', 'audio'], function(v) {
				if(!rich_value[v]) rich_value[v] = [];
			});
			if(rich_value.image.length + rich_value.video.length + rich_value.audio.length == 0)
				return null;
			var media_con = $('<div class="media-preview-con" />');
			_.each(['image', 'video', 'audio'], $.proxy(function(v) {
				medias = rich_value[v];
				for (var i = 0; i < medias.length; i++) {
					var m = medias[i];
					var m_dom = this.hbs({
						type: v, 
						url: $.regex.isUrl(m) ? m : ('/utility/materials/' + m + '/preview')
					}, '/fillers_mobile/media_preview', true);
					m_dom.appendTo(media_con);

					m_dom.colorbox({
						href: $.regex.isUrl(m) ? m : ('/utility/materials/' + m),
						rel: this.model.id,
						opacity: 0.3,
						current: '<span style="margin-left: 2em;">{current} / {total}</span>',
						close: '关闭',
						previous: '向前',
						next: '向后',
						xhrError: '加载资源出错',
						imgError: '加载图片出错',
						photo: (v == 'image'),
						maxWidth: '100%'
					});					
				};
			}, this));
			if(media_con != null)
				parent.append(media_con);
		},

		_render: function() {
			this.replaceElement(this.hbs(this.model.toJSON(), '/fillers_mobile/base', true));
			// render title content and  media
			this.$('.q-title-content').append($.richtext.textToHtml(this.model.get('content')));
			this.renderMediaPreviews(this.$('.q-title'), this.model.get('content'));

			this.refreshIndex();

			this.$el.addClass('q-' + quill.helpers.QuestionType.getName(this.model.get('question_type')).toLowerCase());

			var info = this.model.getInfo();
			if (this.model.get('question_type') == 12){
				info = info.replace(/将右侧选项拖拽至左侧空白处进行排列/,'点击右侧向上或向下箭头进行排序')
			}

			if(!info)
				this.$('.q-info').hide();
			else
				this.$('.q-info').text('（' + info + '）');

			this.model.get('is_required') ? this.$('.q-required').show() : this.$('.q-required').hide();

      var note = this.model.get('note');
      if(note) {
        this.$('.q-note').show();
        if(note.indexOf('<img') == 0) {
          this.$('.q-note').html(note);
        }
      } else {
        this.$('.q-note').hide();
      }
		},

		/* Refresh index display
		 * =========================== */
		refreshIndex: function(index) {
			if(index >= 0) this.options.index = index;
			this.$('.q-idx').text($.util.printNumber(this.options.index + 1));
		},

		/* Set and get the answer of the question
		 * =========================== */
		setAnswer: function(answer) {
			throw 'Override setAnswer method!';
		},
		getAnswer: function() {
			var answer = this._getAnswer();
			var error = this.model.checkAnswer(answer);
			this.$el.removeClass('error');
			this.$('.q-error').text('');
			if(error) {
				this.$el.addClass('error');
				if(_.isString(error))
					this.$('.q-error').text(error);
				else
					this.$('.q-error:eq(' + error.index + ')').text(error.text);
			}
			return {
				answer: answer,
				error: error
			};
		},
		_getAnswer: function() {
			throw 'You should override the method of _getAnswer!';
		},

		/* Destroy widget
		 * =========================== */
		_destroy: function() { }

	});

});
