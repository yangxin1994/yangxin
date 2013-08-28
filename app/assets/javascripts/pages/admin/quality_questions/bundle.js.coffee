$(".btn-add-group").click ->
  len = $(".answer-choices").children().length + 1
  $(".answer-choices").append "<div class=\"group group-" + len + " ui-droppable\"><div class=\"drag-group\" title=\"拖拽删除\"></span>拖拽</span></div></div>"
  $(".drag-group").draggable
    cancel: "input" # clicking an icon won't initiate dragging
    revert: "invalid" # when not dropped, the item will revert back to its initial position
    containment: "document"
    helper: "clone"
    cursor: "move"

  $(".answer-choices .group-" + len).droppable
    accept: ".choices .choice"
    activeClass: "ui-state-highlight"
    drop: (event, ui) ->
      $item = ui.draggable
      
      # $item.clone().appendTo('.answer-choices .group-'+len);
      $item.clone().children("input").addClass("dn").parent().append("<span>" + $item.children("input[type=text]").val() + "</span>").appendTo ".answer-choices .group-" + len  if $(".answer-choices .group-" + len).children("#" + $item.attr("id")).length is 0
      $(".answer-choices .drag-choice").draggable
        cancel: "input" # clicking an icon won't initiate dragging
        revert: "invalid" # when not dropped, the item will revert back to its initial position
        containment: "document"
        helper: "clone"
        cursor: "move"



