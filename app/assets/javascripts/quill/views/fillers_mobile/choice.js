//=require ../../templates/fillers_mobile/choice_op

/* ================================
 * View: Choice question render
 * ================================ */

$(function(){
  
  quill.quillClass('quill.views.fillersMobile.Choice', quill.views.fillersMobile.Base, {
    
    _render: function() {
      var con = this.$('.q-content');

      // shuffle items if necessary
      var indexes = _.range(this.model_issue.items.length);
      if(this.model_issue.is_rand)
        var indexes = _.shuffle(indexes);
      var other_item = this.model_issue.other_item;
      if(other_item && !other_item.has_other_item) other_item = null;

      // setup options
      if(this.model_issue.option_type == 1) {
        // render selector
        var slt = $('<select />').appendTo(con);
        $.each(indexes, $.proxy(function(i, index) {
          var item = this.model_issue.items[index];
          $('<option value=' + item.id + ' />').text(item.content.text).appendTo(slt);
        }, this));
        if(other_item) {
          $('<option value=' + other_item.id + ' />').text(other_item.content.text).appendTo(slt);
          $('<input type="text" />').hide().appendTo(con);
          slt.change($.proxy(function() {
            // show input if necessary
            (parseInt(slt.val()) == other_item.id) ? this.$('input:text').show() : this.$('input:text').hide();
          }, this));
        };
        // setup medias
        $.each(indexes, $.proxy(function(i, index) {
          var item = this.model_issue.items[index];
          var div_dom = $('<div class="opt-media-con" />').attr('id', 'media_' + this.model.id + '_' + item.id).hide().appendTo(con);
          this.renderMediaPreviews(div_dom, item.content);
        }, this));
        if(other_item) {
          var div_dom = $('<div class="opt-media-con" />').attr('id', 'media_' + this.model.id + '_' + other_item.id).hide().appendTo(con);
          this.renderMediaPreviews(div_dom, other_item.content);
        }
        this.$('.opt-media-con:eq(0)').show();
        slt.change($.proxy(function() {
          this.$('.opt-media-con').hide();
          this.$('#media_' + this.model.id + '_' + slt.val()).show();
        }, this));
      } else {
        // render radio/checkbox
        var type = (this.model_issue.option_type == 0) ? 'radio' : 'checkbox';

        // setup options
        var setup_item = $.proxy(function(i) {
          var item = (i < this.model_issue.items.length) ? this.model_issue.items[i] : other_item;
          var $p = this.hbs({
            model_id: this.model.id,
            item_id: item.id,
            type: type,
            html: $.richtext.textToHtml(item.content),
            input: item.has_other_item,
            is_exclusive: item.is_exclusive
          }, '/fillers_mobile/choice_op', true).appendTo(con);
          this.renderMediaPreviews($p, item.content);
          $('input', $p).data('value', item.id);
        }, this);

        for (var i = 0; i < indexes.length; i++)
          setup_item(indexes[i]);
        if(other_item) setup_item(indexes.length);

        // set exclusive
        var set_exclusive = $.proxy(function(ipt) {
          ipt.change($.proxy(function() {
            if(ipt.is(':checked')) {
              if(ipt.hasClass('is_exclusive')) {
                this.$('input:checkbox').attr('checked', null);
                ipt.attr('checked', 'checked');
              } else {
                this.$('input:checkbox.is_exclusive').attr('checked', null);
              }
            }
          }, this));
        }, this);
        $.each(this.$('input:checkbox'), function(){
          set_exclusive($(this));
        });
      }
    },

    setAnswer: function(answer) {
      if(!answer) return;
      if(answer.selection && answer.selection.length > 0) {
        if(this.model_issue.option_type == 1) {
          this.$('select').val(answer.selection[0]);
          this.$('.opt-media-con').hide();
          this.$('#media_' + this.model.id + '_' + answer.selection[0]).show();
          if(this.model_issue.other_item && _.contains(answer.selection, this.model_issue.other_item.id)) {
            this.$('input:text').show();
          }
        } else {
          for (var i = 0; i < answer.selection.length; i++) {
            this.$('#' + this.model.id + '_' + answer.selection[i]).attr('checked', 'checked');
          };
        }
      }
      this.$('input:text').val(answer.text_input);
    },
    _getAnswer: function() {
      var answer = {selection: [], text_input: ''};
      if(this.model_issue.option_type == 1) {
        this.$('select option:selected').each(function () {
          answer.selection.push(parseInt($(this).val()));
        });
      } else {
        this.$('input:checked').each(function(i, v) {
          answer.selection.push($(this).data('value'));
        });
      }
      if(this.model_issue.other_item && _.contains(answer.selection, this.model_issue.other_item.id)) {
        answer.text_input = $.trim(this.$('input:text').val());
      };
      return answer;
    }

  });
  
});
