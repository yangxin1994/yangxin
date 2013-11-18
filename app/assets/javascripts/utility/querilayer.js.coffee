class Querilayer
  constructor: () ->
    @queries = {}
    for _query in document.location.search.substr(1).split('&')
      _query = _query.split('=')
      if _query[0] && _query[1]
        @queries[_query[0].toString()] = decodeURIComponent(_query[1].toString())
    return this

  to_s: (new_queries)->
    for key, value of new_queries
      @queries[key] = value

    _query_str = null
    for key, value of @queries
      if _query_str
        _query_str += "&#{key}=#{value}"
      else
        _query_str = "?#{key}=#{value}"
    _query_str


  to_href: (new_queries)->
    document.location.host + document.location.pathname + this.to_s(new_queries)

window.querilayer = new Querilayer

$ ->
  _tmp_queries = Object.clone(querilayer.queries)
  $('.querilayer').each (index, _this)->
    $this = $(_this)
    href = $this.attr("href").replace "?", ''
    _query_strs = href.split("&")
    for _query_str in  _query_strs
      if _query_str?
        _query = _query_str.split("=")
        querilayer.queries[_query[0]] = _query[1]
    $this.attr("href", querilayer.to_s())
    querilayer.queries = Object.clone(_tmp_queries)
