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
      html_attr:
        type: "checkbox"
    question_html += """
      <label class="checkbox inline">
        #{inner_html}#{question.content.text}
      </label>
    """

  wrapper = """
  <span class="survey_#{survey._id}">
    <li>#{survey.title}<a href="javascript:void(0);" class="survey_remove" data-survey_id="#{survey._id}">移除</a></li>
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
      #{questions_html}
    </select>
  """

question_helper = (question, survey_id, condition_id)->
  questions_html = """
  <div class="question_items survey_#{survey_id}"><p>
    #{question.content.text}<a href="javascript:void(0);" class="question_remove" data-survey_id="#{question._id}">移除</a>
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
  $(".question_selector").select2()

remove_survey = (survey_id) ->
  $(".survey_#{survey_id}").remove()
  delete presurveys[survey_id]
  refresh_question_selectors()

remove_question = () ->
  ""

save = () ->

$(()->
  # initialize
  $("#survey_selector").select2()

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

    console.log conditions
    editing_id = gon.editing._id
    $.ajax
      method: if editing_id then "PUT" else "POST"
      url: if editing_id then "pre_surveys/#{editing_id}" else "pre_surveys"
      async: false
      data:
        pre_survey:
          name: ""
          status: 1
          publish: 
            type: 1
            survey_id: ""
            question_id: ""
          reward_scheme_id: ""
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
    # confirm "确定删除吗?", ->
    remove_survey(survey_id) 

  # restate
  do ->
    console.log "恢复状态"
    surveys_id = []
    i = 0
    return unless gon.editing
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


)



