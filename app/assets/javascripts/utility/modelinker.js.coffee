class Modelinker
  constructor: (options ={})->
    options.klass ||= "modelinker"
    options.data ||= {}
    options.changed ||= (e)->{e}
    @queue = {}
    @callback_queue = {}
    @data = options.data
    @klass = options.klass

    # Linker Event Bind
    $(document).on "change", ".#{@klass}", (event)=>
      $this = $(event.target)
      options.changed($this)
      if $this.is("input")
        if $this.is("input:checkbox")
          @queue["#{$this.data("mid")}"] = if $this.prop("checked") then $this.val() else ""
        else
          @queue["#{$this.data("mid")}"] = $this.val()
      else if $this.is("textarea")
        @queue["#{$this.data("mid")}"] = $this.val()
      else if $this.is("select")
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
    options.klass ||= ""
    _mid = @new_mid()
    options.id ||= _mid
    options.value ||= undefined
    options.prefix ||= undefined
    options.callback ||= (ret)-> ret
    options.html ||= ""
    options.select_options ||= {}
    _html_attr = ""
    _select_options_tag = ""
    for k, v of options.html_attr
      _html_attr += " #{k}#{if v then "=\"#{v}\"" else ''} "
    
    end_tag = if options.single then "" else "</#{options.type}>"
    value_tag = ""
    if options.type
      if options.type == "input"
        switch options.html_attr.type
          when "text"
            value_tag = if options.value then " value=#{options.value} " else ""
            @queue["#{_mid}"] = options.value if options.value
          when "checkbox"
            @queue["#{_mid}"] = options.value if options.html_attr.checked != undefined
            value_tag = " value=#{options.value} "
          else
            @queue["#{_mid}"] = options.value if options.value
      else if options.type == "select"
        for k, v of options.select_options
          if options.html_attr.multiple
            flag = options.value.indexOf(v.toString()) != -1
          else
            flag = options.value.toString() == v.toString()
          
          if flag
            _select_options_tag += """<option value="#{v}" selected="selected">#{k}</option>"""
          else
            _select_options_tag += """<option value="#{v}">#{k}</option>"""
            
          
      else
        @queue["#{_mid}"] = options.html
  
      @callback_queue["#{_mid}"] = options.callback
      @set_obj(options.linker, _mid)
      """
      <#{options.type} 
        id="#{options.id}" 
        class="#{@klass} #{options.klass}"
        data-mid="#{_mid}"
        #{value_tag}
        data-linker="#{options.linker}"#{_html_attr}>#{options.html}#{_select_options_tag}#{end_tag}
      """
    else
      ""

  get_obj: (linker = @data) ->
    linker = @data if typeof(linker) != "object"
    _ret = undefined
    for k, v of linker
      if k.split('_')[0] == "ary"
        _ret ||= []
        if typeof(v) == "string"
          _ret.push @queue["#{v}"]
          @callback_queue["#{v}"](_ret)
        else
          _ret.push @get_obj(v)
      else
        _ret ||= {}
        if typeof(v) == "string"
          _ret["#{k}"] = @queue["#{v}"]
          @callback_queue["#{v}"](_ret)
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
