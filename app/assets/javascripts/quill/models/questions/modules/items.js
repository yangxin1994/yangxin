/* ================================
 * Module to manipulate issue items
 * ================================ */

$(function(){

	window.quill.modules.items = function(model, key, support_other, new_item_func, item_count_changed_func) {
		if(!model || !model.issue) return;

		// new_item_func should be function
		if(!_.isFunction(new_item_func))
			throw 'new_item_func should be a function that return a new item';
		item_count_changed_func = item_count_changed_func || function(model) {};

		// item value key
		var items_key = key + 's', other_key = 'other_' + key;

		// set issue init value
		var issue = model.issue;
		if(!issue[items_key])
			issue[items_key] = [];
		var items = issue[items_key];

		// adjust issue values
		var other_item = issue[other_key];
		if(support_other && (!issue[other_key] || !issue[other_key].content)) {
			issue[other_key] = new_item_func(model, $.richtext.defaultValue('其他（请输入）'));
			issue[other_key].has_other_item = false;
			other_item = issue[other_key];
		}

		// handler
		var handler = {
			key: key,

			/* Items manipulation.
			 * ============================ */
			getItems: function() { return items; },
			findItemIndex: function(id) {
				return _.findIndex(items, function(item) {
					return (item.id == id);
				})
			},
			findItem: function(id) {
				var index = this.findItemIndex(id);
				return index < 0 ? null : items[index];
			},
			addItem: function(content) {
				var new_item = new_item_func(model, content);
				items.push(new_item);
				model.trigger('change:items:add', new_item.id, handler);
				item_count_changed_func(model);
			},
			updateItem: function(id, content) {
				var item = this.findItem(id);
				if(!item) return;
				item.content = content;
				model.trigger('change:items:update', id, handler);
			},
			removeItem: function(id) {
				var index = this.findItemIndex(id);
				if(index < 0) return;
				items.splice(index, 1);
				model.trigger('change:items:remove', id, handler);
				item_count_changed_func(model);
			},
			moveItem: function(id, target_index) {
				// move item to some position
				if(target_index < 0 || target_index >= items.length) return;
				var old_index = this.findItemIndex(id);
				if(old_index < 0 || old_index == target_index) return;
				var item = items[old_index];
				items.splice(old_index, 1);
				items.splice(target_index, 0, item);
				model.trigger('change:items:move', id, target_index, handler);
			},
			
			/* item count
			 * ===================== */
			itemCount: function() {
				return items.length + ((support_other && other_item.has_other_item) ? 1 : 0)
			}
		};

		/* Other item manipulation.
		 * ============================ */
		if(support_other) {
			$.extend(handler, {
				setOther: function(hasOther) {
					other_item.has_other_item = hasOther;
					model.trigger('change:items:set_other', true, handler);
					item_count_changed_func(model);
				},
				updateOther: function(otherContent) {
					other_item.content = otherContent;
					model.trigger('change:items:update_other', false, handler);
				},
				getOther: function() {
					return other_item;
				}
			});
		}

		/* Serialize the items to array codes. 
		 * Deserialize the items from array codes.
		 * =========================== */
		$.extend(handler, {
			_serialize_items: function() {
				var codes = _.map(items, function(item) {
					return item.content.text;
				});
				if(support_other && other_item.has_other_item) {
					codes.push(other_item.content.text);
				}
				return codes;
			},
			_deserialize_items: function(item_codes) {
				item_codes = _.reject(item_codes, function(str) {
					return str == '';
				});
				if(item_codes.length == 0) {
					if(support_other) this.setOther(false);
				} else {
					if(support_other) {
						if(other_item.has_other_item || _.last(item_codes).startsWith('其他')) {
							this.setOther(true);
							this.updateOther($.extend(other_item.content, { text: _.last(item_codes) }));
							item_codes = _.first(item_codes, item_codes.length - 1);
						}
					}
					var i = 0;
					while(i<item_codes.length) {
						if(i < items.length) {
							this.updateItem(items[i].id, 
								$.extend(items[i].content, { text: item_codes[i] }));
						} else {
							this.addItem($.richtext.defaultValue(item_codes[i]));
						}
						i++;
					}
					while(i < items.length) {
						this.removeItem(items[i].id);
					}
				}
			}
		});

		return handler;
	};

});