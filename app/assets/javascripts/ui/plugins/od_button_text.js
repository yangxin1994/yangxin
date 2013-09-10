/* ================================
 * Change button text or later restore the old text
 * ================================ */

(function( $ ) {
  $.widget("oopsdata.odButtonText", {
 
    // These options will be used as defaults
    options: { 
      text: null
    },
 
    // Set up the widget
    _create: function() {
    	if(!this.element.is('button'))
    		throw 'odButtonText can only apply on buttons';
    	this.element.data('odButtonText_value', this.element.text());
    	if(this.options.text) {
    		this.element.text(this.options.text);
    	}
    },

    restore: function() {
    	this.element.text(this.element.data('odButtonText_value'));
    },
 
    // Use the destroy method to clean up any modifications your widget has made to the DOM
    destroy: function() {
    	this.restore();
    	this.element.data('odButtonText_value', null);
      $.Widget.prototype.destroy.call(this);
    }
  });
}(jQuery));