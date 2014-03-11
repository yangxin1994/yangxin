#= require soso_map
$ ->
  if window.locations == ""
    map = new soso.maps.Map(document.getElementById('map'))
  else
    center = new soso.maps.LatLng("35.245619", "104.839783")
    map = new soso.maps.Map(document.getElementById('map'),{center: center, zoom: 4})
    locations = window.locations.split('-')
    for location in locations
      temp = location.split(',')
      lat = temp[0]
      lng = temp[1]
      point = new soso.maps.LatLng(lat, lng)
      marker = new soso.maps.Marker({position: point, map: map})