#=require utility/modelinker

$ ->
  # 预置事件
  window.modelinker = new Modelinker

  $('#myTab a').click (e)->
    e.preventDefault()
    $(this).tab('show')

  # helpers
    
  render_attr = (smp_attr) ->
    switch smp_attr.type
      when 0
        input = modelinker.generate
          type: "textarea"
          linker: "attr.#{smp_attr._id}"
          html: smp_attr.pmt_value
          html_attr:
            rows: "6"
            placeholder:"字符串类型:请填写需要过滤的内容."

      when 1, 7
        input = ""
        smp_attr.pmt_value ||= []
        for item, i in smp_attr.enum_array
          _html_attr = {type: "checkbox"}
          if smp_attr.pmt_value.indexOf(i.toString()) != -1
            _html_attr.checked = ''
          input += """<label class="checkbox inline">
            #{
              modelinker.generate
                type: "input"
                linker: "attr.#{smp_attr._id}.ary_#{i}"
                value: i.toString()
                html_attr: _html_attr
                html: item
            }
            </label>
            """
      when 2, 4
        input = """<div class="controls controls-row">
          #{
            modelinker.generate
              type: "input"
              linker: "attr.#{smp_attr._id}.ary_0"
              klass: "span2"
              value: smp_attr.pmt_value[0]
              html_attr:
                type: "text"
                placeholder: "最小值"
          }
          #{
            modelinker.generate
              type: "input"
              linker: "attr.#{smp_attr._id}.ary_1"
              klass: "span2"
              value: smp_attr.pmt_value[1]
              html_attr:
                type: "text"
                placeholder: "最大值"
          }
          <span class="help-inline">
            <a href="javascript:void(0);"><i class="icon-plus-sign"></i></a>
            <a href="javascript:void(0);"><i class="icon-minus-sign"></i></a>
          </span>                 
          </div>
          """
      when 3, 5
        console.log smp_attr.pmt_value
        min_date = Date.create(smp_attr.pmt_value[0] * 1000)
        max_date = Date.create(smp_attr.pmt_value[1] * 1000)
        input = """
        <div class="controls controls-row">
          #{
            modelinker.generate
              type: "input"
              linker: "attr.#{smp_attr._id}.min.ary_y"
              klass: "span2"
              value: min_date.getFullYear()
              html_attr:
                type: "text"
                placeholder: "年"
              html: item
          }
          #{
            if smp_attr.date_type > 0
              modelinker.generate
                type: "input"
                linker: "attr.#{smp_attr._id}.min.ary_m"
                klass: "span1"
                value: min_date.getMonth() + 1
                html_attr:
                  type: "text"
                  placeholder: "年"
                html: item
          }
          #{
            if smp_attr.date_type > 1
              modelinker.generate
                type: "input"
                linker: "attr.#{smp_attr._id}.min.ary_d"
                klass: "span1"
                value: min_date.getDay()
                html_attr:
                  type: "text"
                  placeholder: "年"
                html: item
          }
          <span class="span1">~</span>

          #{
            modelinker.generate
              type: "input"
              linker: "attr.#{smp_attr._id}.max.ary_y"
              klass: "span2"
              value: max_date.getFullYear()
              html_attr:
                type: "text"
                placeholder: "年"
              html: item
          }
          #{
            if smp_attr.date_type > 0
              modelinker.generate
                type: "input"
                linker: "attr.#{smp_attr._id}.max.ary_m"
                klass: "span1"
                value: max_date.getMonth() + 1
                html_attr:
                  type: "text"
                  placeholder: "年"
                html: item
          }
          #{
            if smp_attr.date_type > 1
              modelinker.generate
                type: "input"
                linker: "attr.#{smp_attr._id}.max.ary_d"
                klass: "span1"
                value: max_date.getDay()
                html_attr:
                  type: "text"
                  placeholder: "年"
                html: item
          }
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
      else
        input = """
          <div class="bs-docs-example">
            <textarea rows="6" placeholder="我觉得还是重试吧!"></textarea>
          </div>
        """

    """
      <div class="bs-docs-example" 
           data-id="#{smp_attr._id}" 
           data-type="#{smp_attr.type}"
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

  # 数据初始化

  do ->
    $.ajax
      method: "GET"
      url: "sample_attributes"
      async: false
      data: 
        id: gon.id
      success: (ret)->
        if ret.success
          window.gon.smp_attrs = {}
          for smp_attr in ret.value
            window.gon.smp_attrs["#{smp_attr._id}"] = smp_attr          
        else
          alert_msg.show('error', "系统繁忙请刷新页面 (╯‵□′)╯︵┻━┻")

      error: ->
        alert_msg.show('error', "系统繁忙请刷新页面 (╯‵□′)╯︵┻━┻")
    for pmt_attr in gon.pmt_attrs
      if smp_attr = gon.smp_attrs["#{pmt_attr.sample_attribute_id}"]
        smp_attr.pmt_value = pmt_attr.value
        $("#attr-placeholder").before(render_attr(smp_attr))
        $("#attr-placeholder").prev().fadeIn(200)

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
    $.ajax
      method: "DELETE"
      url: "remove_sample_attribute_for_promote"
      data:
        sample_attribute_id: $this_div.data("id")
      success: (ret)->
        if ret.success
          alert_msg.show('success', "删除成功!")
          $this_div.fadeOut(500)
        else
          alert_msg.show('error', "删除失败 (╯‵□′)╯︵┻━┻")

      error: ->
        alert_msg.show('error', "删除失败 (╯‵□′)╯︵┻━┻")    
    
    # setInterval(500, $this_div.remove())

  $(document).on 'click', ".btn-attr-save", ->
    $this = $(this)
    $this_div = $this.closest('.bs-docs-example')
    _value = modelinker.get("attr.#{$this_div.data("id")}")
    switch $this_div.data("type")
      when 1, 7
        _value.remove("")
      when 2, 4
        _value
      when 3, 5
        _min = _value.min.join('-')
        _max = _value.min.join('-')
        _value = [Date.parse(_min)/1000, Date.parse(_max)/1000]
      else
        _value
    _value
      
    if $this.hasClass("disabled")
      # do nothing
    else
      $.ajax
        method: "PUT"
        url: "update_sample_attribute_for_promote"
        data:
          sample_attribute:
            sample_attribute_id: $this_div.data("id")
            value: _value
        success: (ret)->
          if ret.success
            $this.closest(".attr-group").remove()
            $this.html("已保存").addClass("disabled")
            alert_msg.show('success', "保存成功!")
          else
            alert_msg.show('error', "保存失败 (╯‵□′)╯︵┻━┻")

        error: ->
          alert_msg.show('error', "保存失败 (╯‵□′)╯︵┻━┻")



    

