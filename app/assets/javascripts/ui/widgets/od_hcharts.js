//=require ./_base
//=require ./_templates/od_hcharts
//=require highcharts
//=require highcharts.exporting
 
/* ================================
 * The Hcharts widget
 * ================================ */

(function($) {
	
	$.odWidget('odHcharts', {
		
		/* The default setting for plugin
		 * ================================ */
		options: {
			id_name: 'od-hcharts-container'
		},

		/* Gloabal settings for odHcharts
		 * ================================ */
		//general	
		$chart: {
			backgroundColor: "#FFFFFF",
			zoomType: ""
		},
		//series colors
		$colors: ['#f5c000', '#5F2ABD', '#FAC802', '#489E44', '#E83131', '#3D96AE', '#DB843D', '#92A8CD', '#A47D7C', '#B5CA92'],
		$credits: {
			enabled: true,
			href: "http://www.oopsdata.com/",
			text: "OopsData Consultants"
		},
		//exporting
		$exporting: {
			enabled: true,
			enableImages: false,
			url: "http://export.highcharts.com"
		},
		//language
		$lang: {
			printButtonTitle: "打印图表",
			exportButtonTitle: "导出图表",
			downloadJPEG: "下载为JPEG",
			downloadPNG: "下载为PNG",
			downloadSVG: "下载为SVG",
			downloadPDF: "下载为PDF"			
		},
		//the odHcharts object
		$hchart: null,

		/* Set up the widget
		 * ================================ */
		_createEl: function() {
			this.element = this.hbs(this.options);
		},

		drawBar: function(option) {
			//it seems more uncomfortable to merge these general setting in _createEl
			option.lang = this.$lang;
			option.exporting = this.$exporting;		
			option.credits = this.$credits;
			option.colors = this.$colors;
			// option.chart = this.$chart;
			option.chart.renderTo = this.options.id_name;
			option.chart.type = 'bar';

			this.$hchart = new Highcharts.Chart(option);
		},

		drawColumn: function(option) {
			option.lang = this.$lang;
			option.exporting = this.$exporting;
			option.credits = this.$credits;
			option.colors = this.$colors;
			// option.chart = this.$chart;
			option.chart.renderTo = this.options.id_name;
			option.chart.type = 'column';

			this.$hchart = new Highcharts.Chart(option);
		},

		drawLine: function(option) {
			option.lang = this.$lang;
			option.exporting = this.$exporting;
			option.credits = this.$credits;
			option.colors = this.$colors;
			option.chart = this.$chart;
			option.chart.renderTo = this.options.id_name;
			option.chart.type = 'line';

			this.$hchart = new Highcharts.Chart(option);
		},

		drawArea: function(option) {
			option.lang = this.$lang;
			option.exporting = this.$exporting;
			option.credits = this.$credits;
			option.colors = this.$colors;
			option.chart = this.$chart;
			option.chart.renderTo = this.options.id_name;
			option.chart.type = 'area';

			this.$hchart = new Highcharts.Chart(option);
		},

		drawPie: function(option) {
			option.lang = this.$lang;
			option.exporting = this.$exporting;
			option.credits = this.$credits;
			option.colors = this.$colors;
			// option.chart = this.$chart;
			option.chart.renderTo = this.options.id_name;
			option.chart.type = 'pie';

			this.$hchart = new Highcharts.Chart(option);
		},

		drawSpline: function(option) {
			option.lang = this.$lang;
			option.exporting = this.$exporting;
			option.credits = this.$credits;
			option.colors = this.$colors;
			option.chart = this.$chart;
			option.chart.renderTo = this.options.id_name;
			option.chart.type = 'spline';

			this.$hchart = new Highcharts.Chart(option);
		},

		drawScatter: function(option) {
			option.lang = this.$lang;
			option.exporting = this.$exporting;
			option.credits = this.$credits;
			option.colors = this.$colors;
			option.chart = this.$chart;
			option.chart.renderTo = this.options.id_name;
			option.chart.type = 'scatter';

			this.$hchart = new Highcharts.Chart(option);
		}											
		
	});

})(jQuery);