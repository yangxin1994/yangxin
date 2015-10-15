#=require utility_admin/modelinker

$ ->
  # 预置事件
  window.modelinker = new Modelinker
    changed: ($this)->
      $this.closest(".bs-docs-example")
        .find(".btn-attr-save")
        .removeClass("disabled")
        .html("*保存")

  $('#myTab a').click (e)->
    e.preventDefault()
    $(this).tab('show')
    
  do ->
    $(".attr-id").each ->
      $this = $(this)
      $this.prev("ul").find("a[href='#attr-#{$this.val()}']").click()
    
    $(".dropselect").each ->
      $this = $(this)
      _val = $this.next('input').val()
      $this.find('a').each ->
        $_this = $(this)
        if $_this.attr("href").split('-')[1] == _val
          $_this.click()

  # helpers

  address_input = (smp_attr) ->

    modelinker.generate
      type: "select"
      linker: "attr.#{smp_attr._id}"
      value: smp_attr.pmt_value
      klass: ".province-group"
      select_options:
        安徽省: 49152
        北京市: 4096
        福建省: 53248
        甘肃省: 114688
        广东省: 77824
        广西壮族自治区: 81920
        贵州省: 98304
        海南省: 86016
        河北省: 12288
        河南省: 65536
        黑龙江省: 32768
        湖北省: 69632
        湖南省: 73728
        吉林省: 28672
        江苏省: 40960
        江西省: 57344
        辽宁省: 24576
        内蒙古自治区: 20480
        宁夏回族自治区: 122880
        青海省: 118784
        山东省: 61440
        山西省: 16384
        陕西省: 110592
        上海市: 36864
        四川省: 94208
        天津市: 8192
        西藏自治区: 106496
        新疆维吾尔自治区: 126976
        云南省: 102400
        浙江省: 45056
        重庆市: 90112

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
        smp_attr.pmt_value ||= []
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
        smp_attr.pmt_value ||= []
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
                  placeholder: "月"
                html: item
            else
              ""
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
                  placeholder: "日"
                html: item
            else
              ""
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
                  placeholder: "月"
                html: item
            else
              ""
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
                  placeholder: "日"
                html: item
            else
              ""
          }
          <span class="help-inline">
            <a href="javascript:void(0);"><i class="icon-plus-sign"></i></a>
            <a href="javascript:void(0);"><i class="icon-minus-sign"></i></a>
          </span>
        </div>        
        """
      when 6
        console.log smp_attr.pmt_value
        input = modelinker.generate
          type: "select"
          linker: "attr.#{smp_attr._id}"
          value: smp_attr.pmt_value
          klass: ".province-group"
          html_attr:
            multiple: "multiple"
            size: 6
          select_options:
            安徽省: 49152
            北京市: 4096
            福建省: 53248
            甘肃省: 114688
            广东省: 77824
            广西壮族自治区: 81920
            贵州省: 98304
            海南省: 86016
            河北省: 12288
            河南省: 65536
            黑龙江省: 32768
            湖北省: 69632
            湖南省: 73728
            吉林省: 28672
            江苏省: 40960
            江西省: 57344
            辽宁省: 24576
            内蒙古自治区: 20480
            宁夏回族自治区: 122880
            青海省: 118784
            山东省: 61440
            山西省: 16384
            陕西省: 110592
            上海市: 36864
            四川省: 94208
            天津市: 8192
            西藏自治区: 106496
            新疆维吾尔自治区: 126976
            云南省: 102400
            浙江省: 45056
            重庆市: 90112
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
        _value = _value.filter (i)->
          i != null && i != undefined && i != ""
      when 2, 4
        _value
      when 3, 5
        _min = _value.min.join('-')
        _max = _value.max.join('-')
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

  $('.btn-ckb').click ->
    $this = $(this)
    if $this.hasClass('active')
      $("##{$this.data('toggle')}_promotable").val(false)
      $(".#{$this.data('toggle')}-info")?.hide()
    else
      $("##{$this.data('toggle')}_promotable").val(true)
      $(".#{$this.data('toggle')}-info")?.show()


  $('.btn-pack').click(->
    if $(this).hasClass('active')
      $('#open_red_pack').val(false)
    else
      $('#open_red_pack').val(true)
  )

  $(document).on 'click','.attr-li', ->
    $this = $(this)
    _placeholder = ""
    switch $this.attr("href").split('_')[1].toNumber()
      when 0
        _placeholder = "字符串:请直接输入要筛选的字符串内容"
      when 1
        _placeholder = ""
      when 2, 4
        _placeholder = "数值类型:每行包含两个元素的数组，两个元素均为数字,用逗号分隔，分别代表日期范围的最小值和最大值"
      when 3, 5
        _placeholder = "日期类型:每行包含两个元素的数组，两个元素均为YYYY/MM/DD,用逗号分隔，分别代表日期范围的最小值和最大值"
      when 6
        _placeholder = "枚举类型:每行代表一项枚举"
      when 7
        _placeholder = "数组类型:每行代表数组内的一项"
    $("#attr-ipt-#{$this.data('index')}").attr("placeholder", _placeholder)

  $(document).on 'click','.dropselect a', ->
    $this = $(this)
    $this.parent().parent().next('input').val($this.attr('href').split('-')[1])

  $('.btn-ckb').each ->
    $this = $(this)
    $(".#{$this.data('toggle')}-info")?.hide() unless $this.hasClass('active')

  $('#add_browser_extension_setting').click ->
    $this = $(this)
    index = $this.data('toggle') + 1
    add_html = """
    <div class="control-group browser_extension-info">
      <label class="control-label" >浏览器插件详细设置:</label>
      <div class="controls">
        <input type="text" placeholder="在这里输入关键字" id="weibo_text" name="browser_extension[browser_extension_promote_setting][filters][#{index}][key_words]" />
      </div>
    </div>
    <div class="control-group browser_extension-info">
      <div class="controls">
        <input type="text" placeholder="在这里输入网址" id="weibo_text" name="browser_extension[browser_extension_promote_setting][filters][#{index}][url]" />
      </div>
    </div>
    """
    $this.data('toggle', index)
    $this.parent().parent().parent().prepend(add_html)


  $('#add_agent_setting').click ->
    $this = $(this)
    type_html = $("#type_select_0").html()
    index = $this.data('toggle') + 1
    agent_list = $("#agent_select_0").html() 
    add_html = """
      <div class="control-group agent-info">
        <label class="control-label">奖励方案设置:</label>
        <div class="controls">
          <div class="btn-group">
            <button class="btn dropdown-toggle" data-toggle="dropdown">
              奖励方案
              <span class="caret"></span>
            </button>
            <ul class="dropdown-menu dropselect agent-reward">
              #{type_html}
            </ul>
            <input type="hidden" name="agent[agent_promote_setting][agents][#{index}][reward_scheme_id]"/>
          </div>
        </div>
      </div>    
      <div class="control-group agent-info">
        <label class="control-label">代理选择:</label>
        <div class="controls">
          <div class="btn-group">
            <button class="btn dropdown-toggle" data-toggle="dropdown">
              代理选择
              <span class="caret"></span>
            </button>
            <ul class="dropdown-menu dropselect" id="agent_select_#{index}">
              #{agent_list}
            </ul>
            <input type='hidden' name="agent[agent_promote_setting][agents][#{index}][agent_id]" palceholder=""/>
          </div>
        </div>
      </div>
      <div class="control-group agent-info">
        <label class="control-label">回收数量:</label>
        <div class="controls">
          <input type='text' name="agent[agent_promote_setting][agents][#{index}][count]" palceholder=""/>
        </div>
      </div>   
      <div class="control-group agent-info">
        <label class="control-label">描述:</label>
        <div class="controls">
          <textarea name="agent[agent_promote_setting][agents][#{index}][description]" rows ="5">
          </textarea>        
        </div>
      </div>
    """
    $this.data('toggle', index)
    $this.parent().parent().parent().prepend(add_html)



    

