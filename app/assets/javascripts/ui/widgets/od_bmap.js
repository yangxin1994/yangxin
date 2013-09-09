//=require ./_base
//=require ./_templates/od_bmap
//=require TextIconOverlay-min
//=require MarkerClusterer-min
 
/* ================================
 * The Bmap widget
 * ================================ */

(function($) {
	
	$.odWidget('odBmap', {
		
		/* The default setting for plugin
		 * ================================ */
		options: {
			id_name: 'od-bmap',
			width: 697,
			height: 550
		},
		
		/* Set up the widget
		 * ================================ */
		_createEl: function() {
			this.element = this.hbs(this.options);
		},
		$map: null,
		$markerClusterer: null,

		init: function() {
			this.$map = new BMap.Map(this.options.id_name);
			this.$markerClusterer = new BMapLib.MarkerClusterer(this.$map);
			var point = new BMap.Point(103.966951,36.026247);//定义一个中心点坐标
        	this.$map.centerAndZoom(point,5);//设定地图的中心点和坐标并将地图显示在地图容器中
			this.$map.addControl(new BMap.NavigationControl());  
			this.$map.addControl(new BMap.OverviewMapControl());
			this.$map.enableScrollWheelZoom();
		},

		clearOverlays: function() {
			this.$map.clearOverlays();
		},

		setRegion: function(name, color, title, content) {
			var boundary = new BMap.Boundary();
			var map = this.$map;
			boundary.get(name, function(rs) {
				for(var i = 0; i < rs.boundaries.length; i ++) {
					var polygon = new BMap.Polygon(rs.boundaries[i], {fillColor: color});			
            		map.addOverlay(polygon);

            		polygon.addEventListener("click", function() {
            			map.setViewport(polygon.getPath());
						var infoWindow = new BMap.InfoWindow(content, {title: title});
						map.openInfoWindow(infoWindow,map.getCenter());
            		});
            		
				};
			});
		},

		setMarker: function(name, title, content, scope) {		//scope should be the last
			var map = this.$map;
			var markerClusterer = this.$markerClusterer;

			var gc = new BMap.Geocoder(); 
			gc.getPoint(name, function(point){  
 				if (point) {
 					var marker = new BMap.Marker(point, {title: name}); 
 					markerClusterer.addMarker(marker);
   					map.addOverlay(marker);
   					marker.addEventListener("click", function(){
   						var infoWindow = new BMap.InfoWindow(content, {title: title});
   						this.openInfoWindow(infoWindow);
   					});
 				};

			}, scope);					
		},

		setMarkerLL: function(name, title, content, latitude, longitude) {
			var map = this.$map;
			var markerClusterer = this.$markerClusterer;
			var point = new BMap.Point(longitude, latitude);

			var marker = new BMap.Marker(point, {title: name}); 
			markerClusterer.addMarker(marker);
			map.addOverlay(marker);
			marker.addEventListener("click", function(){
				var infoWindow = new BMap.InfoWindow(content, {title: title});
				this.openInfoWindow(infoWindow);
			});

		},

		setCenter: function(latitude, longitude) {
			var map = this.$map;
			var point = new BMap.Point(longitude, latitude);
			map.setCenter(point);
		}

	});
	
})(jQuery);
