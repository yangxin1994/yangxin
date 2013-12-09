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
   * option:
   * onReady
   * onUnready
   * =========================== */
  quill.quillClass('quill.views.SurveyEditor', quill.views.Base, {

    _initialize: function() { 
      this.model.on('change:title', this.refreshTitle, this);
      this.model.on('change:subtitle', this.refreshSubtitle, this);
      this.model.on('change:description', this.refreshDescription, this);
    },

    _is_ready: false,
    _setReady: function() {
      this._is_ready = true;
      this.options.onReady();
    },
    _setUnready: function() {
      this._is_ready = false;
      this.options.onUnready();
    },

    _render: function() {
      this.replaceElement(this.hbs(this.model.toJSON()));

      /* edit survey title
       * =============================== */
      var save_title = $.proxy(function() {
        $.util.disable(this.$('.ex-title input'), this.$('.ex-title button'));
        this.$('.ex-title button strong').text('正在保存...');
        this.model.updateBasic(this.$('.ex-title .survey-title').val(), 
          this.$('.ex-title .survey-subtitle').val(), this.$('.ex-title .survey-description').val(), {
          success: $.proxy(function() {
            this.$('.ex-title').hide();
            this.$('.ex-title-finished-con').show();
            this._setReady();
          }, this), 
          after: $.proxy(function() {
            $.util.enable(this.$('.ex-title input'), this.$('.ex-title button'));
            this.$('.ex-title button strong').text('确定');
          }, this)
        });
      }, this);
      this.$('.ex-title button').mousedown(save_title);
      var start_edit_title = $.proxy(function() {
        this.$('.ex-title').show();
        this.$('.ex-title-finished-con').hide();
        this.$('.ex-title input:eq(0)').focus();
      }, this);
      this.$('.ex-title-finished-con button').click(start_edit_title);
      this.refreshDescription();

      /* render pages one by one
       * =============================== */
      var _render_page = $.proxy(function(page_index) {
        if(page_index >= this.model.pageCount()) {
          this.refreshPageIndexes();
          this.refreshQuestionIndexes();
          if(this.model.isNew()) {
            start_edit_title();
            this._setUnready();
          } else {
            this._setReady();
          }
          return;
        }

        // get one page questions and render
        this.model.getQuestions(page_index, {

          success: $.proxy(function(q_models) {
            // 1. render one page questions
            var qids = this.model.get('pages')[page_index].questions;
            var _render = $.proxy(function(question_index) {
              if(question_index >= qids.length) return;
              this.renderQuestion(qids[question_index], $.proxy(function() {
                this.findQDesigner(qids[question_index]).setRound((question_index == 0), (question_index == qids.length - 1));
                _render(question_index + 1);
              }, this));
            }, this);
            _render(0);
            // 2. render page index
            this._newPageIndex(page_index).appendTo(this.$('.s-pages'));
            // 3. render next page questions
            _render_page(page_index + 1);
          }, this), 

          error: $.proxy(function(err) { }, this)

        });
      }, this);
      _render_page(0);  // start to render pages

      // make questions sortable
      this.$('.s-pages').sortable({
        cancel: ".page-index, .drop-question",
        start: $.proxy(function(event, ui) {
          $('.q-render', ui.helper).addClass('dragging');
          ui.helper.data('view').setRound(true, true);
        }, this),
        stop: $.proxy(function(event, ui) {
          $('.q-render', ui.item).removeClass('dragging');
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
     * Refresh
     * ================================================== */
    refreshTitle: function() {
      this.$('.ex-title .survey-title').val(this.model.get('title'));
      this.$('.ex-title-finished h1').text(this.model.get('title'));
    },
    refreshSubtitle: function() {
      this.$('.ex-title .survey-subtitle').val(this.model.get('subtitle'));
      this.$('.ex-title-finished h2').text(this.model.get('subtitle'));
    },
    refreshDescription: function() {
      this.$('.ex-title .survey-description').val(this.model.get('description'));
      this.$('.ex-title-finished .survey-description-finished').html('<p>' + _.map(this.model.get('description').split(/\r\n|\r|\n/igm), function(v) {
        return $.richtext.textToHtml({text: v});
      }).join('</p><p>') + '</p>');
    },

    /* ==================================================
     * Page related methods
     * ================================================== */

    /* Split one page into two pages
     * =========================== */
    splitPage: function(before_question_id) {
      var page_dom = this._newPageIndex(0).insertBefore(this.findQDesigner(before_question_id).$el);
      this.adjustDesignerRound(page_dom.prev().data('view'), page_dom.next().data('view'));
      this.refreshPageIndexes();
      this.model.splitPage(before_question_id, {
        success: function() {},
        error: function() {}
      });
    },

    /* Combine two pages into one
     * =========================== */
    combinePages: function(page_index) {
      var page_dom = this.findPageIndexDom(page_index);
      var prev_designer = page_dom.prev().data('view'), next_designer = page_dom.next().data('view');
      this.findPageIndexDom(page_index).remove();
      this.adjustDesignerRound(prev_designer, next_designer);
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
            if(this._current_designer == designer)
              this._current_designer = null;
            this.$('.s-pages').sortable('enable');
            if(designer) 
              this.adjustDesignerRound(designer, designer.$el.prev().data('view'), designer.$el.next().data('view'));
          }, this),
          onOpenEditor: $.proxy(function() {
            if(this._current_designer && this._current_designer != designer) {
              this._current_designer.openRender();
            }
            this._current_designer = designer;
            this.$('.s-pages').sortable('disable');
            if(designer) {
              var prev_designer = designer.$el.prev().data('view'), next_designer = designer.$el.next().data('view');
              if(prev_designer) prev_designer.setBottom(true);
              if(next_designer) next_designer.setTop(true);
            }
            // scroll to the designer
            var $w = $(window), $d = designer.$el, padding = 10, time = 500;
            if($w.scrollTop() > $d.offset().top) {
              $w.scrollTo($d, time, { offset: {top: 0-padding} });
            } else if($w.scrollTop() + $w.height() < $d.offset().top + $d.height()) {
              if(($d.height() + padding)< $w.height()) {
                $w.scrollTo($d, time, { offset: {top: $d.height() + padding - $w.height()} });
              } else {
                $w.scrollTo($d, time, { offset: {top: 0-padding} });
              }
            }
            // focus on title input
            $('.q-title textarea', designer.$el).focus();
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
      this._setUnready();
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
            this._setReady();
          }, this)

        });

      }, this);

      var $w = $(window);
      if(adding_q_dom.offset().top > $w.scrollTop() + $w.height() || 
        adding_q_dom.offset().top + adding_q_dom.height() < $w.scrollTop()) {
        $w.scrollTo(adding_q_dom, 500, { 
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
          var designer = this.findQDesigner(question_id);
          var pre_designer = designer.$el.prev().data('view'), next_designer = designer.$el.next().data('view');
          designer.remove();
          this.adjustDesignerRound(pre_designer, next_designer);
          this.refreshQuestionIndexes();
        }, this),

        error: failed_callback
      });
    },

    /* Move question
     * TODO: waiting for finish 
     * =========================== */
    moveQuestion: function(question_id, after_question_id, page_index) {
      // move question
      this.model.moveQuestion(question_id, after_question_id, page_index, {
        success: function() {},
        error: function() {}
      });
      // adjust ui
      var q_designer = this.findQDesigner(question_id), q_designer_dom = q_designer.$el.detach()
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
      // set designer round
      this.adjustDesignerRound(q_designer, q_designer_dom.prev().data('view'), q_designer_dom.next().data('view'));
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
    },

    /* Adjust the round corner of designers in arguments
     * =========================== */
    adjustDesignerRound: function(designers) {
      _.each(arguments, function(d, i) {
        if(d) d.setRound(!d.$el.prev().hasClass('q-designer'), !d.$el.next().hasClass('q-designer'));
      });
    }

  }); // survey editor

});
