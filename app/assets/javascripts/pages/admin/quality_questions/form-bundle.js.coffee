//= require jquery-ui-draggable
$ ->
  # ######################
  #
  #       new 部分
  #
  # ######################

  $(document).on 'click', '.qnumber a', ->
    $this = $(this)
    info = $this.attr('href').split('-')
    $this.parent().parent().next().val(info[1])

  # ######################
  #
  #       show 部分
  #
  # ######################

  $(".choice, .answer-choices .drag-choice, .drag-group").draggable
    cancel: "input" # clicking an icon won't initiate dragging
    revert: "invalid" # when not dropped, the item will revert back to its initial position
    containment: "document"
    helper: "clone"
    cursor: "move"

  $.each $(".answer-choices .group"), (index, group) ->
    $(group).droppable
      accept: ".choice"
      activeClass: "ui-state-highlight"
      drop: (event, ui) ->
        $item = ui.draggable
        if $(group).children("#" + $item.attr("id")).length is 0
          $ic = $item.clone()
          $ic.children('.drag-choice').html("拖拽: #{$item.children("input[type=text]").val()}")
          $ic.children('span.delete').remove()
          $ic.children('input').remove()
          $ic.appendTo group
        # $item.clone().children('input').addClass('dn').parent().appendTo(group);
        #$item.clone().children("input").addClass("display-none").parent().append("<span>" + $item.children("input[type=text]").val() + "</span>").appendTo group  if $(group).children("#" + $item.attr("id")).length is 0
        $(".answer-choices .drag-choice").draggable
          cancel: "input" # clicking an icon won't initiate dragging
          revert: "invalid" # when not dropped, the item will revert back to its initial position
          containment: "document"
          helper: "clone"
          cursor: "move"

  $("body").droppable
    accept: ".answer-choices .drag-choice, .answer-choices .drag-group"
    activeClass: ""
    drop: (event, ui) ->
      $item = ui.draggable
      $item.parent().remove()

  $(".add-choice").click ->
    $this = $(this)
    choice_index = $this.parent().find(".choice").length
    html = """
      <div class="input-prepend input-append choice" data-id="choice-#{Date.now()}#{choice_index}">
        <span class="add-on drag-choice">拖拽</span>
        <input class="span7 choice-text" id="appendedPrependedInput" type="text" value="新选项">
        <span class="add-on delete"><a href="#" class="btn-choice-delete"><i class="icon-remove"></i></a></span>
      </div>
      <p></p>
    """
    $(html).appendTo($this.prev('.controls')).draggable
      cancel: "input", 
      revert: "invalid",
      containment: "document",
      helper: "clone",
      cursor: "move"

  $(".controls").on 'click', '.btn-choice-delete', ->
    _p = $(this).parent().parent()
    _p.next("p").remove()
    _p.remove()

  $("#btn_sub").click ->
    _answers = ""
    $('.answer-choices .choice').each ->
      $this = $(this)
      window.$this = $this
      _answers += ",#{$this.data('id').split('-')[1]}"
    $('#answers').val(_answers)

  do ->
    $("#qtab-0").click()

