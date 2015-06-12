//=require ../../templates/fillers_mobile/scale
//=require ../../templates/fillers_mobile/scale_guide
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
			var labels = this.model_issue.labels
			if(this.model_issue.show_unknown) {
				labels = ['不清楚'].concat(this.model_issue.labels)			
			}

			for(var i = 0;i < labels.length;i ++){
				if($.inArray('不清楚',labels) >= 0){
					this.hbs({
						item_text: i + ":" + labels[i]
					}, '/fillers_mobile/scale_guide', true).appendTo(this.$('.q-content'));		
				}else{
					this.hbs({
						item_text: (i + 1) + ":" + labels[i]
					}, '/fillers_mobile/scale_guide', true).appendTo(this.$('.q-content'));	
				}
			}


			for(var i = 0; i < indexes.length; i ++) {
				var item = this.model_issue.items[indexes[i]];
				var $div = this.hbs({
					item_id: item.id,
					item_text: $.richtext.textToHtml(item.content)
				}, '/fillers_mobile/scale', true).appendTo(this.$('.q-content'));
				this.renderMediaPreviews($('.subhead', $div), item.content);

				for (var c = 0; c < this.model_issue.labels.length; c++) {
					var $p = this.hbs({
						item_id: item.id,
						label_id: item.id + "-" + c,
						index: c,
						label_text: c + 1
					}, '/fillers_mobile/scale_op', true).insertAfter($('.subhead', $div));
				};
				if(this.model_issue.show_unknown) {
					this.hbs({
						item_id: item.id,
						label_id: item.id + "-unknown",
						index: -1,
						label_text: 0
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
