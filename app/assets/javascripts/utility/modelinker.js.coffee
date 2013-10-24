class Modelinker
  constructor: (data = {}, klass= "modelinker")->
    @queue = {}
    @data = data
    @klass = "modelinker"

    # Linker Event Bind
    $(document).on "change", ".#{@klass}", (event)=>
      $this = $(event.target)
      if $this.is("input") || $this.is("textarea")
        @queue["#{$this.data("mid")}"] = $this.val()
      else
        @queue["#{$this.data("mid")}"] = $this.html()
      
    this

  new_mid: (prefix = null)->
    if prefix
      mid = "#{prefix}-"
    else
      mid = ""
    mid += "#{Math.random(Date.now).toString().replace('0.','')}"
    mid      

  add: ($this, data = null)->    
    $this.data("")

  set_obj: (linker, mid) ->
    linker = linker.split('.')
    last_linker = @data
    for l, i in linker
      last_linker["#{l}"] ||= {}
      if i == linker.length - 1
        last_linker["#{l}"] = mid
      else
        last_linker = last_linker["#{l}"]
    @data
      
  generate: (options = {}) ->

    options.class ||= ""
    _mid = @new_mid()
    options.id ||= _mid
    options.value ||= undefined
    options.prefix ||= undefined
    html_attr = ""
    for k, v of options.html_attr
      html_attr += " #{k}=\"#{v}\""
    options.html ||= ""
    
    end_tag = if options.single then "" else "</#{options.type}>"
    if options.type
      @queue["#{_mid}"] = options.value
      @set_obj(options.linker, _mid)
      """
      <#{options.type} 
        id="#{options.id}" 
        class="#{@klass} #{options.class}"
        data-mid="#{_mid}"
        data-linker="#{options.linker}"#{html_attr}>#{options.html}#{end_tag}
      """
    else
      ""

  get_obj: (linker = @data) ->
    linker = @data if typeof(linker) != "object"
    _ret = {}
    for k, v of linker
      if typeof(v) == "string"
        _ret["#{k}"] = @queue["#{v}"]
      else
        _ret["#{k}"] = @get_obj(v)
    _ret
  
  get: (linker = "") ->
    _linker = linker.split('.')
    last_linker = @data
    for key in _linker
      last_linker = last_linker["#{key}"]

    if typeof(last_linker) == "string"
      @queue["#{last_linker}"]
    else
      @get_obj(last_linker)

window.Modelinker = Modelinker
