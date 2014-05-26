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
  <span>
    <li>#{survey.title}<a href="javascript:void(0);">移除</a></li>
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

question_helper = (question, survey_id)->
  questions_html = "<p>#{question.content.text}</p>"
  for item in question.issue.items
    inner_html = modelinker.generate
      type: "input"
      value: "true"
      linker: "conditions.#{survey_id}.#{question._id}.answers.#{item.id}"
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
    value: "true"
    linker: "conditions.#{survey_id}.#{question._id}.fuzzy"
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
    linker: "conditions.#{survey_id}.#{question._id}.survey_id"
    html_attr:
      type: "hidden"
  questions_html +=  inner_html
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
    $("#question_selector_#{$('.question_selector').length - 1}").select2()

remove_survey = () ->
  ""

remove_question = () ->
  ""

save = () ->

# initialize

do ->
  console.log "恢复状态"

# events
$(()->
  $("#survey_selector").select2()
  $("#question_selector_0").select2()

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
    $this.closest(".condition").find(".question_placeholder").append(question_helper(selected_question, survey_id))

  $('.btn-add_condition').click ->
    $("#condition").append(condition_helper())
    refresh_question_selectors()

  $('.btn-save').click ()->
    conditions = []
    for cid, cvalue of modelinker.get("conditions")
      for k, v of cvalue
        answers = []
        for answer_id, is_checked of v.answers
          answers.add(answer_id) if is_checked
        conditions.add
          question_id: k
          survey_id: v.survey_id
          fuzzy: v.fuzzy
          answer: answers

    console.log conditions
    $.ajax
      method: "POST"
      url: "pre_surveys"
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
          alert_msg.show('save', "保存成功！")
        else
          alert_msg.show('error', "系统繁忙请稍后再试 (╯‵□′)╯︵┻━┻")

      error: ->
        alert_msg.show('error', "系统繁忙请稍后再试 (╯‵□′)╯︵┻━┻")
    return false
)



