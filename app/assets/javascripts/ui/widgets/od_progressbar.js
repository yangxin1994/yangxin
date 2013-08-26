//=require ./_base
//=require ./_templates/od_progressbar
 
/* ================================
 * The Progressbar widget
 * ================================ */

(function($) {

	$.odWidget('odProgressbar', {

		/* The default setting for plugin
		 * ================================ */
		options: {
			width: 200,
			value: 0,
			color: "#6D91A9"
		},

		$bar: null,
		$value: null,
		
		/* Set up the widget
		 * ================================ */
		_createEl: function() {
			var options = {
				back_width: this.options.width,
				front_width: this.options.width * this.options.value,
				color: this.options.color
			};
			this.element = this.hbs(options);
			this.$bar = this._find('.od-progress-front');
			this.$value = this._find('.od-progress-value');
			this.$value.text(Math.floor(100*this.options.value)+"%");
		},
		/* Set option value
		 * ================================ */
		_setOption: function(key, val) {
			switch(key) {
				case "value":
					var front_width = this.options.width * val;
					this.$bar.css("width", front_width);
					this.$value.text(Math.floor(100 * val)+"%");
			}
			$.Widget.prototype._setOption.apply(this, arguments);
		},

		fixedTimer: function(time, interval, hide, end, callback) {
			var bw = this.options.width;
			if(arguments[4] == undefined)
				callback = function(){};
			var the_end = (end == undefined) ? 1 : end;
			var ew = the_end*bw;
			var fw = this.options.value*bw;
			this.options.value = the_end;		//the value after animation
			var timeStep = time/interval;
			var widthStep = (ew-fw)/interval;
			var flag = 0;
			var percentStep = (100*(ew-fw)/bw)/interval;
			var percent = 100*fw/bw;
			var value = this.$value;

			this.$bar.animate({width: "+="+widthStep}, timeStep, progress);

			function progress() {
				if (flag < (interval-1)) {
					flag += 1;					
					percent += percentStep;
					$(this).animate({width: "+="+widthStep}, timeStep, progress);
					value.text(Math.floor(percent)+"%");
				} else {
					$(this).css("width", ew+1);
					value.text(Math.floor(100*the_end) + "%");
					if(hide)
						$(this).parent().parent().fadeOut(2000, "linear", function(){callback();})
					else
						callback();
				}
			}
		},

		realTimer: function() {

		}

	});

})(jQuery);