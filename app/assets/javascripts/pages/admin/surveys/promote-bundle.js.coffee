#=require utility/modelinker

$ ->
  # 预置事件
  window.modelinker = new Modelinker

  $('#myTab a').click (e)->
    e.preventDefault()
    $(this).tab('show')

  # helpers

  add_time_ipt = ($this) ->
    $parent = $this.closest('.bs-docs-example')
    data = gon.attr_data["#{$parent.data('oid')}"]
    data["#{new_oid()}"] = ""
    $this.closest('.controls-row').append(
      """
        <div class="controls controls-row">
          <input class="span2" type="text" placeholder="年">
          #{"<input class=\"span1\" type=\"text\" placeholder=\"月\">" if date_type > 0}
          #{"<input class=\"span1\" type=\"text\" placeholder=\"日\">>" if date_type > 1}
          <span class="span1">~</span>
          <input class="span2" type="text" placeholder="年">
          #{"<input class=\"span1\" type=\"text\" placeholder=\"月\">" if date_type > 0}
          #{"<input class=\"span1\" type=\"text\" placeholder=\"日\">>" if date_type > 1}
          <span class="help-inline">
            <a href="javascript:void(0);"><i class="icon-plus-sign"></i></a>
            <a href="javascript:void(0);"><i class="icon-minus-sign"></i></a>
          </span>
        </div> 
      """
    )

  add_num_ipt = () ->
    ""
    
  render_attr = (smp_attr) ->
    console.log smp_attr
    switch smp_attr.type
      when 0
        input = modelinker.generate
          type: "textarea"
          linker: "attr.#{smp_attr._id}.#{Date.now()}"
          html_attr:
            rows: "6"
            placeholder:"字符串类型:请填写需要过滤的内容."

      when 1
        input = """
        """
      when 2, 4
        input = """
        <div class="controls controls-row">
          <input class="span3" type="text" placeholder=".span3">
          <input class="span3" type="text" placeholder=".span3">
          <span class="help-inline">
            <a href="javascript:void(0);"><i class="icon-plus-sign"></i></a>
            <a href="javascript:void(0);"><i class="icon-minus-sign"></i></a>
          </span>
        </div>
        """
      when 3, 5
        input = """
        <div class="controls controls-row">
          <input class="span2" type="text" placeholder="年">
          <input class="span1" type="text" placeholder="月">
          <input class="span1" type="text" placeholder="日">

          <span class="span1">~</span>

          <input class="span2" type="text" placeholder="年">
          <input class="span1" type="text" placeholder="月">
          <input class="span1" type="text" placeholder="日">
          <span class="help-inline">
            <a href="javascript:void(0);"><i class="icon-plus-sign"></i></a>
            <a href="javascript:void(0);"><i class="icon-minus-sign"></i></a>
          </span>
        </div>        
        """
      when 6
        input = """
          <textarea rows="6" placeholder="地址类型:请填写需要过滤的内容."></textarea>
        """      
      when 7
        input = """
        """             
      else
        input = """
          <div class="bs-docs-example">
            <textarea rows="6" placeholder="我觉得还是重试吧!"></textarea>
          </div>
        """

    """
      <div class="bs-docs-example" 
           data-id="#{smp_attr._id}" 
           data-date_type="#{smp_attr.date_type}"
           data-date_type="#{smp_attr.date_type}"
           data-element_type="#{smp_attr.element_type}
           data-enum_array="#{smp_attr.enum_array}"
           style="display:none" >
        <div class="row">
          <span class="span1">
          </span>  
          <span class="span9">
            <p>
              [#{attr_type(smp_attr)}]#{smp_attr.name}
            </p>
            #{input}
          </span>  
          <span class="span2">
            <p>
              <button class="btn btn-small btn-blocks btn-primary btn-attr-save" type="button">保存*</button>
            </p>
            <p>
              <button class="btn btn-small btn-blocks btn-danger btn-attr-del" type="button">删除</button>
            </p>
            
          </span>  
        </div>
      </div>
    """

  attr_type = (smp_attr) ->
    get_type = (_type) ->
      switch _type
        when 0
          "字符串"
        when 1
          if smp_attr.element_type == 1 or smp_attr.element_type == 7
            "枚举"
          else
            "枚举(#{get_type(smp_attr.element_type)})"
        when 2
          "数值"
        when 3
          "日期"
        when 4
          "数值范围"
        when 5
          "日期范围"
        when 6
          "地址"
        when 7
          if smp_attr.element_type == 1 or smp_attr.element_type == 7
            "数组"
          else
            "数组(#{get_type(smp_attr.element_type)})"
        else
          ""

    get_type(smp_attr.type)

  # 事件绑定
  $("#attr_add_btn").click ->
    $this = $(this)

    $.ajax
      method: "GET"
      url: "sample_attributes"
      async: false
      data: 
        id: gon.id
      success: (ret)->
        if ret.success
          btns_str = """<li><a href="#">取消</a></li>"""
          last_type = null
          window.gon.smp_attrs = {}
          for smp_attr in ret.value
            window.gon.smp_attrs["#{smp_attr._id}"] = smp_attr
            if smp_attr.type != last_type
              btns_str += """<li class="divider"></li>"""
            btns_str += """<li><a href="#" data-attr_id="#{smp_attr._id}" class="">[#{attr_type(smp_attr)}]#{smp_attr.name}</a></li>"""
            $("#btn_panel").html(btns_str)
            last_type = smp_attr.type
        else
          alert_msg.show('error', "系统繁忙请稍后再试 (╯‵□′)╯︵┻━┻")

      error: ->
        alert_msg.show('error', "系统繁忙请稍后再试 (╯‵□′)╯︵┻━┻")

  $(document).on 'click','#btn_panel a', ->
    $this = $(this)
    smp_attr = gon.smp_attrs["#{$this.data('attr_id')}"]
    $("#attr-placeholder").before(render_attr(smp_attr))
    $("#attr-placeholder").prev().fadeIn(500)
  false

  $(document).on 'click', ".btn-attr-del", ->
    $this = $(this)
    $this_div = $this.closest('.bs-docs-example')
    $this_div.fadeOut(500)
    # setInterval(500, $this_div.remove())

  $(document).on 'click', ".btn-attr-save", ->
    $this = $(this)
    $this_div = $this.closest('.bs-docs-example')
    if $this.hasClass("disabled")
      # do nothing
    else
      $.ajax
        method: "PUT"
        url: "update_sample_attribute"
        data:
          sample_attribute:
            sample_attribute_id: $this_div.data("id")
            value: modelinker.get("attr.#{$this_div.data("id")}")
        success: (ret)->
          if ret.success
            $this.closest(".attr-group").remove()
            $this.html("已保存").addClass("disabled")
            alert_msg.show('success', "保存成功!")
          else
            alert_msg.show('error', "保存失败 (╯‵□′)╯︵┻━┻")

        error: ->
          alert_msg.show('error', "保存失败 (╯‵□′)╯︵┻━┻")

    

