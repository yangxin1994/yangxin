$(".btn-choice-delete").click ->
  _id = $(this).parent().attr("id")
  $(".choices #" + _id).remove()
  $(".answer-choices #" + _id).remove()
  false

