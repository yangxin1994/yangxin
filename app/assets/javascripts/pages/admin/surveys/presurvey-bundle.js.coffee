#=require select2
#=require utility_admin/modelinker
#= require sugar-1.3.9.min
window.modelinker = new Modelinker
window.presurveys = {}

survey_helper = (survey)->

  """<input id="1914171187672764" class="modelinker " data-mid="1914171187672764" value="0" data-linker="attr.522884c0eb0e5b0845000004.ary_0" type="checkbox">"""
  question_html = ""
  for question in survey.email_questions
    inner_html = modelinker.generate
      type: "input"
      value: question._id
      linker: "surveys.#{question._id}"
      klass: "publish_ipt"
      html_attr:
        type: "checkbox"
        "data-type": if survey.question_type == 4 then 1 else 2
    question_html += """
      <label class="checkbox inline">
        #{inner_html}#{question.content.text}
      </label>
    """

  wrapper = """
  <span class="survey_#{survey._id}">
    <li>#{survey.title}<a href="javascript:void(0);" class="survey_remove" data-survey_id="#{survey._id}"><i class="icon-remove"></i></a></li>
      <label class="checkbox">
        #{question_html}
      </label>
  </span>
  """

# question_helper = (question)->

#   item_html = ""
#   for item in question.issue.items
#     inner_html = modelinker.generate
#       type: "input"
#       value: question._id
#       linker: "conditions.questions.#{question._id}"
#       html_attr:
#         type: "checkbox"
#     question_html += """
#       <label class="checkbox">
#         #{inner_html}#{item.content.text}
#       </label>
#     """
#   wrapper = """
#   <p>#{question.content.text}</p>
#   #{question_html}
#   """

question_selector_helper = ()->
  questions_html = ""
  for survey_id, survey of presurveys
    for question in survey.choice_questions
      questions_html += """
        <option value="#{question._id},#{survey_id}">#{question.content.text}</option>
      """
  wrapper = """
    <select id="question_selector_#{$(".question_selector").length}" class="question_selector">
      <option></option>
      #{questions_html}
    </select>
  """

question_helper = (question, survey_id, condition_id)->
  questions_html = """
  <div data-linker="conditions.#{condition_id}.#{question._id}" class="question_items survey_#{survey_id}"><p>
    #{question.content.text}<a href="javascript:void(0);" class="question_remove" data-survey_id="#{question._id}"><i class="icon-remove"></i></a>
  </p>
  """
  for item in question.issue.items
    inner_html = modelinker.generate
      type: "input"
      value: item.id
      linker: "conditions.#{condition_id}.#{question._id}.answers.#{item.id}"
      html_attr:
        type: "checkbox"
    questions_html += """
    <label class="checkbox">
      #{inner_html}#{item.content.text}
    </label>
    """
  # fuzzy 
  inner_html = modelinker.generate
    type: "input"
    value: "fuzzy"
    linker: "conditions.#{condition_id}.#{question._id}.fuzzy"
    html_attr:
      type: "checkbox"
  questions_html += """
    <label class="checkbox">
      #{inner_html}<i>模糊匹配</i>
    </label>
    """
  # survey_id
  inner_html = modelinker.generate
    type: "input"
    value: survey_id
    linker: "conditions.#{condition_id}.#{question._id}.survey_id"
    html_attr:
      type: "hidden"
  questions_html +=  inner_html
  questions_html += "</div>"
  questions_html

condition_helper = ()->
  """
  <div class="well condition" id="condition_#{modelinker.new_mid()}">
    <div class="question_placeholder"></div>
  </div> 
  """

refresh_question_selectors = () ->
  for question in $(".question_selector")
    $(question).remove()
  for question_panel in $(".condition")
    $(question_panel).append(question_selector_helper())
    # $("#question_selector_#{$('.question_selector').length - 1}").select2()
  $(".question_selector").select2(
    width:"element"
    placeholder: "请选择要添加的问题"

    )

remove_survey = (survey_id) ->
  delete presurveys[survey_id]
  for _linker in $(".survey_#{survey_id}")
    remove_question $(_linker)
  $(".survey_#{survey_id}").remove()
  refresh_question_selectors()

remove_question = ($question) ->
  modelinker.remove $question.data("linker")
  console.log $question.data("linker")
  $question.remove()
  

save = () ->

$(()->
  # initialize
  $("#survey_selector").select2(
    width:"element"
    placeholder: "请选择要作为预调研的问卷"
    )

  # events

  $("#survey_selector").change (e)->
    $this = $(this)
    survey =
      title: this.selectedOptions[0].innerHTML
      _id: $this.val()
    questions_html = $(".question_selector").html()
    $.ajax
      method: "GET"
      url: "pre_surveys/questions"
      async: false
      data: 
        survey_ids: survey._id
        stype: "0|4|6"
      success: (ret)->
        if ret.success
          presurveys[survey._id] = ret.value
          survey.email_questions = ret.value.email_questions
          survey.choice_questions = ret.value.choice_questions
        else
          alert_msg.show('error', "系统繁忙请稍后再试 (╯‵□′)╯︵┻━┻")

      error: ->
        alert_msg.show('error', "系统繁忙请稍后再试 (╯‵□′)╯︵┻━┻")

    $("#survey_list").append(survey_helper(survey))
    refresh_question_selectors()
    # $(".question_placeholder").append(question_selector_helper(survey.choice_questions, true))
    # $("#question_selector_#{$('.question_selector').length - 1}").select2()

  $(document).on "change", ".question_selector", (e)->
    $this = $(this)
    $condition = $this.closest('.condition')
    survey_id = $this.val().split(',')[1]
    selected_question_id = $this.val().split(',')[0]
    selected_question = undefined
    for question in presurveys[survey_id].choice_questions
      selected_question = question if question._id == selected_question_id
    $this.closest(".condition").find(".question_placeholder").append(question_helper(selected_question, survey_id, $condition.attr("id").split("_")[1]))

  $('.btn-add_condition').click ->
    $("#condition").append(condition_helper())
    refresh_question_selectors()

  $('.btn-save').click ()->
    conditions = []
    i = 0
    for cid, cvalue of modelinker.get("conditions")
      cdt = []
      continue unless cvalue
      for k, v of cvalue
        continue unless v
        answers = []
        for answer_id, is_checked of v.answers
          answers.add(answer_id) if is_checked
        cdt.add
          question_id: k
          survey_id: v.survey_id
          fuzzy: v.fuzzy
          answer: answers
      conditions[i] = cdt.clone()
      i += 1

    editing_id = gon.editing._id
    $select_publish = undefined
    for publish_ipt in $(".publish_ipt")
      if $(publish_ipt).prop("checked")
        $select_publish = $(publish_ipt)

    if $select_publish
      select_publish = 
        type: $select_publish.data("type")
        survey_id: $select_publish.data("linker").split(".")[1]
        question_id: $select_publish.val()
    else
      select_publish = {}
    $.ajax
      method: if editing_id then "PUT" else "POST"
      url: if editing_id then "pre_surveys/#{editing_id}" else "pre_surveys"
      async: false
      data:
        pre_survey:
          name: $("#pres_name").val()
          status: if $("#pres_status").prop("checked") then 2 else 1
          publish:
            select_publish
          reward_scheme_id: $("#rs_selector").val()
          conditions: conditions
      success: (ret)->
        if ret.success
          alert_msg.show('save', "创建成功！")
        else
          alert_msg.show('error', "系统繁忙请稍后再试 (╯‵□′)╯︵┻━┻")

      error: ->
        alert_msg.show('error', "系统繁忙请稍后再试 (╯‵□′)╯︵┻━┻")
    return false

  $(document).on "click", ".survey_remove", ->
    survey_id = $(this).data("survey_id")
    if confirm("问卷移除之后，条件设置中有关该问卷的问题都会被删除掉，确定移除问卷吗?")
      remove_survey(survey_id)

  $(document).on "click", ".question_remove", ->
    if confirm("确定移除该问题吗?")
      $question = $(this).closest("div.question_items")
      remove_question($question)

  $(".btn-delete").click ->
    if confirm("确定删除该方案吗?")
      console.log gon.editing._id
      $.ajax
        method: "DELETE"
        url: "pre_surveys/#{gon.editing._id}"
        async: false
        success: (ret)->
          if ret.success
            alert_msg.show('save', "删除成功！")
            document.location = location.pathname
          else
            alert_msg.show('error', "系统繁忙请稍后再试 (╯‵□′)╯︵┻━┻")

        error: ->
          alert_msg.show('error', "系统繁忙请稍后再试 (╯‵□′)╯︵┻━┻")

  $(document).on "click", ".publish_ipt", ->
    for publish_ipt in $(".publish_ipt")
      if publish_ipt != this
        $(publish_ipt).prop("checked", false)

  # restate
  do ->
    console.log "恢复状态"
    surveys_id = []
    i = 0
    return true unless gon.editing
    for condition in gon.editing.conditions
      $(".btn-add_condition").click()
      for question in condition
        if surveys_id.indexOf(question.survey_id) < 0
          surveys_id.add(question.survey_id)
          $survey_selector = $("#survey_selector")
          $survey_selector.val(question.survey_id)
          $survey_selector.change()
        $question_selector = $("#question_selector_#{i}")
        $question_selector.val("#{question.question_id},#{question.survey_id}")
        $question_selector.change()
        if question.answer
          $condition = $question_selector.closest(".condition")
          for item in $condition.find("input")
            if question.answer.indexOf(item.value.toString()) >= 0
              $(item).click()
              continue
            $(item).click() if item.value == "fuzzy" && question.fuzzy

      i += 1
    for publish_ipt in $(".publish_ipt")
      $publish_ipt = $(publish_ipt)
      if gon.editing.publish.question_id == $publish_ipt.val()
        $(publish_ipt).prop("checked", true)
    $("#rs_selector").val(gon.editing.reward_scheme_id)

)



