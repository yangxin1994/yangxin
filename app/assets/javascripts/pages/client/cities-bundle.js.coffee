#= require soso_map

$ ->
  if window.locations == ""
    map = new soso.maps.Map(document.getElementById('map'))
  else
    locations = window.locations.split('-')
    center = new soso.maps.LatLng(locations[0].split(',')[0], locations[0].split(',')[1])
    if window.one_record
      map = new soso.maps.Map(document.getElementById('map'),{center: center, zoom: 10})
    else
      map = new soso.maps.Map(document.getElementById('map'),{center: center, zoom: 6})
    for location in locations
      temp = location.split(',')
      lat = temp[0]
      lng = temp[1]
      point = new soso.maps.LatLng(lat, lng)
      marker = new soso.maps.Marker({position: point, map: map})

  soso.maps.event.addListener(map, "rightclick", (event) ->
    city_id = window.city_id
    record_index = window.record_index
    $.ajax
      url: "/client/cities/#{city_id}/update_location"
      data: { record_index: record_index, lat: event.latLng.getLat(), lng: event.latLng.getLng()}
      method:"PUT"
      success: (ret)->
        if ret.success
          point = new soso.maps.LatLng(event.latLng.getLat(), event.latLng.getLng())
          marker.setVisible(false)
          marker = new soso.maps.Marker({position: point, map: map})
      error: (ret)->
  )