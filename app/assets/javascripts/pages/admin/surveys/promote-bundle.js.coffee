$ ->

  $('#myTab a').click (e)->
    e.preventDefault()
    $(this).tab('show')

  $('.btn-ckb').click ->
    $this = $(this)
    if $this.hasClass('active')
      $("##{$this.data('toggle')}_promotable").val(false)
      $(".#{$this.data('toggle')}-info")?.hide()
    else
      $("##{$this.data('toggle')}_promotable").val(true)
      $(".#{$this.data('toggle')}-info")?.show()

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
    <div class="control-group broswer_extension-info">
      <label class="control-label" >浏览器插件详细设置:</label>
      <div class="controls">
        <input type="text" placeholder="在这里输入关键字" id="weibo_text" name="broswer_extension[broswer_extension_promote_setting][filters][#{index}][key_words]" />
      </div>
    </div>
    <div class="control-group broswer_extension-info">
      <div class="controls">
        <input type="text" placeholder="在这里输入网址" id="weibo_text" name="broswer_extension[broswer_extension_promote_setting][filters][#{index}][url]" />
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
            <input type="hidden" name="agent[agent_promote_setting][agents][#{index}][agent_id]"/>
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

  # #####################
  #  
  # 属性设置
  #
  # #####################

  $(".attr-delete").click ->
    $this = $(this)
    console.log $this.data("index")
    $.ajax
      method: "DELETE"
      url: "destroy_attributes"
      data:
        sample_attribute_index: $this.data("index")
      success: (ret)->
        if ret.success
          console.log $this.closest(".attr-group").html()
          $this.closest(".attr-group").remove()
          alert_msg.show('success', "已经删除!")
        else
          alert_msg.show('error', "删除失败 (╯‵□′)╯︵┻━┻")

      error: ->
        alert_msg.show('error', "删除失败 (╯‵□′)╯︵┻━┻")

    false

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

  
