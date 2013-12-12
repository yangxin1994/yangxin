//=require ../base
//=require ../../models/questions
//=require ../../templates/editors/base
//=require ui/express_widgets/od_checkbox
//=require ui/express_widgets/od_rich_input
//=require ui/plugins/od_button_text
//=require twitter/bootstrap/tooltip
//=require jquery.hotkeys

/* ================================
 * Namespace for oopsdata.views.editors
 * ================================ */

$(function(){
	
	/* Base editor class
	 * Options:
	 *   index: int
	 *   cancel: function() {}
	 *   confirm: function() {}
	 * =========================== */
	quill.quillClass('quill.views.editors.Base', quill.views.Base, {
		
		events: {
			'click .unfold-btn': 'showHidden',
			'click .packUp-btn': 'hideHidden'
		},
		
		model_issue: null,

		_initialize: function() {
			this.model_issue = this.model.get('issue');
			
			this.model.on('change:content', this.refreshTitle, this);
			this.model.on('change:is_required', this.refreshRequired, this);
			this.model.on('change:note', this.refreshNote, this);
		},

		_render: function() {
			this.replaceElement(this.hbs(this.model.toJSON(), 'base'));
			
			/* Refresh question index and question type
			 * ========================== */
			this.refreshIndex();
			this.$('.q-type').append(quill.helpers.QuestionType.getLabel(this.model.get('question_type')));

			/* 1. add toggle between code and visual buttons
			 * 2. set event handlers for toggle buttons
			 * ========================== */
			var $code = this.$('.editor-left-body-code textarea');
			var to_code = $.proxy(function() {
				$code.val(this.model.serialize().join('\r\n'));
			}, this);
			var from_code = $.proxy(function() {
				this.model.deserialize($code.val().split(/\r?\n/));
			}, this);
			$code.blur(from_code);
			this.$('.editor-method >a').tooltip({placement: 'bottom'});
			this.$('.editor-method .eye').click($.proxy(function() {
					from_code();
					this.$('.editor-left-body-visual').show();
					this.$('.editor-left-body-code').hide();
					this.$('.editor-method >a').toggleClass('active');
			}, this)).click();
			this.$('.editor-method .pc').click($.proxy(function() {
					to_code();
					this.$('.editor-left-body-visual').hide();
					this.$('.editor-left-body-code').show();
					this.$('.editor-method >a').toggleClass('active');
					$code.focus().trigger('select');
			}, this));

			/* Cancel and confirm buttons
			 * ========================== */
			this._$cancel_btn = this.$('.btn-cancel').click(this.options.cancel);
			this._$confirm_btn = this.$('.btn-confirm').click($.proxy(function() {
				$.util.disable(this._$cancel_btn, this._$confirm_btn);
				this.model.save({
					error: $.proxy(function() {
						$.util.disable(this._$cancel_btn, this._$confirm_btn);
						//TODO show error message
					}, this),
					success: this.options.confirm
				});
			}, this));
			
			// question title
			$.od.odRichInput({
				id: this._domId('title_ipt'),
				width: 575,
				multiline: true
			}).appendTo(this.$('.q-title'));
			this._findDom('title_ipt').odRichInput('innerInput').blur($.proxy(function() {
				this.model.set('content', this._findDom('title_ipt').odRichInput('val'));
			}, this)).mouseover(function(e){
				$(this).select();
			}).keydown($.proxy(function(e) {
				// press tab, then focus on the first item rich input
				if(e.which == 9) {
					this.$('.od-item:first').odItem('richInput').odRichInput('innerInput').focus();
					return false;
				}
			}, this));
			this.refreshTitle();
			
			// required
			this.addRightItem($.od.odCheckbox({	
				id: this._domId('required_ckb'),
				checked: this.model.get('is_required'),
				text: '必答题',
				onChange: $.proxy(function(checked) {
					this.model.set('is_required', checked);
				}, this)
			}));
			this.refreshRequired();
				
			// note
			this.addRightItem($.od.odCheckbox({	
				id: this._domId('note_ckb'),
				checked: !!this.model.get('note'),
				text: '答题指导',
				onChange: $.proxy(function(checked) {
					this.model.set('note', checked ? '请在此输入答题指导' : '');
				}, this)
			}), true);
			this.$('.q-note textarea').blur($.proxy(function(e) {
				this.model.set('note', $(e.target).val());
			}, this));
			this.refreshNote();
			
			// hotkeys
			this._bindHotkeys();
		},
		_destroy: function() {
			this._unbindHotkeys();
		},

		/* Hotkeys
		 * =========================== */
		_hk_confirm: null,
		_bindHotkeys: function() {
			// this._hk_confirm = $.proxy(this.confirm, this);
			// $(document).bind('keydown', 'ctrl+s', this._hk_confirm);	// not work when focus on input
		},
		_unbindHotkeys: function() {
			// $(document).unbind('keydown', 'ctrl+s', this._hk_confirm);
		},

		/* Add item to right
		 * =========================== */
		_hidden_doms: null,
		_addRight: function(dom, hidden) {
			if(!this._hidden_doms)
				this._hidden_doms = [];
			this.$('.after_items').before(dom);
			if(hidden) {
				if($.inArray(dom, this._hidden_doms) > -1) return;
				this._hidden_doms.push(dom.hide());
			}
			return dom;
		},
		showHidden: function() {
			var self = this;
			$.each(this._hidden_doms, function(i, v) {
				v.slideDown(100, $.proxy(function() {
					this.$('.unfold-btn').hide();
					this.$('.packUp-btn').show();
				}, self));
			});
		},
		hideHidden: function() {
			$.each(this._hidden_doms, function(i, v) {
				v.slideUp(100, $.proxy(function() {
					this.$('.unfold-btn').show();
					this.$('.packUp-btn').hide();
				}, self));
			});
		},
			
		/* Add right item editor
		 * =========================== */
		addRightItem: function($obj, hidden) {
			this._addRight($('<div class="item" />').append($obj), hidden);
			return $obj;
		},
			
		/* Add right item title
		 * =========================== */
		addRightTitle: function(title, hidden) {
			return this._addRight($('<h2 />').text(title), hidden);
		},

		/* Add right item bold title
		 * =========================== */
		addRightBoldTitle: function(title, hidden) {
			return this._addRight($('<h1 />').text(title), hidden);
		},
		
		/* Add right item title
		 * =========================== */
		addRightBar: function(hidden) {
			return this._addRight($('<div class="dotted" />'), hidden);
		},

		/* ================================================
		 * Public methods
		 * ================================================ */
		
		/* Refresh index display
		 * =========================== */
		refreshIndex: function(index) {
			if(index >= 0) this.options.index = index;
			this.$('.q-type strong').text($.util.printNumber(this.options.index + 1));
		},

		/* Confirm and cancel
		 * =========================== */
		_$cancel_btn: null,
		_$confirm_btn: null,
		cancel: function() {
			this._$cancel_btn.trigger('click');
		},
		confirm: function() {
			this._$confirm_btn.trigger('click');
		},
		
		/* Refresh title
		* =========================== */
		refreshTitle: function() {
			this._findDom('title_ipt').odRichInput('val', this.model.get('content'));
		},
		
		/* Refresh required checkbox
		* =========================== */
		refreshRequired: function() {
			this._findDom('required_ckb').odCheckbox('val', this.model.get('is_required'));
			this.model.get('is_required') ? this.$('.star').show() : this.$('.star').hide();
		},
		
		/* Refresh note
		 * =========================== */
		refreshNote: function() {
			var note = this.model.get('note');
			this.$('.q-note textarea').val(note);
			!note ? this.$('.q-note').hide() : this.$('.q-note').show();
			this._findDom('note_ckb').odCheckbox('val', !!note);
		}
		
	});

});