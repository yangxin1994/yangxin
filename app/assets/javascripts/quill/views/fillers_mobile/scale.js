//=require ../../templates/fillers_mobile/scale
//=require ../../templates/fillers_mobile/scale_op

/* ================================
 * View: Scale question render
 * ================================ */

$(function(){

	quill.quillClass('quill.views.fillersMobile.Scale', quill.views.fillersMobile.Base, {
		
		_render: function() {

			// shuffle items if necessary
			var indexes = _.range(this.model_issue.items.length);
			if(this.model_issue.is_rand)
				var indexes = _.shuffle(indexes);

			// setup options
			for(var i = 0; i < indexes.length; i ++) {
				var item = this.model_issue.items[indexes[i]];
				var $div = this.hbs({
					item_id: item.id,
					item_text: item.content.text
				}, '/fillers_mobile/scale', true).appendTo(this.$('.q-content'));
				this.renderMediaPreviews($('.subhead', $div), item.content);

				for (var c = 0; c < this.model_issue.labels.length; c++) {
					var $p = this.hbs({
						item_id: item.id,
						label_id: item.id + "-" + c,
						index: c,
						label_text: this.model_issue.labels[c]
					}, '/fillers_mobile/scale_op', true).insertAfter($('.subhead', $div));
				};
				if(this.model_issue.show_unknown) {
					this.hbs({
						item_id: item.id,
						label_id: item.id + "-unknown",
						index: -1,
						label_text: "不清楚"
					}, '/fillers_mobile/scale_op', true).insertBefore($('.q-divide', $div));
				};
				if(i == (indexes.length - 1))
					$('.q-divide', $div).remove();
			};

		},

		setAnswer: function(answer) {
			if(!answer) return;
			$.each(this.model_issue.items, $.proxy(function(i, item){
				var v = answer[item.id], tr = this.$('#' + item.id);
				if(v == undefined) return;
				if(v < 0) {
					if(this.model_issue.show_unknown) {
						this.$('#' + item.id + "-unknown").attr('checked', 'checked');
					}
				} else {
					this.$('#' + item.id + "-" + v).attr('checked', 'checked');
				}
			}, this));
		},
		_getAnswer: function() {
			var answer = {};
			this.$('input:checked').each(function(i, v) {
				var item_id = $(this).attr("name");
				answer[item_id] = Number($(this).attr("value"));
			});
			return answer;
		}

	});
	
});
