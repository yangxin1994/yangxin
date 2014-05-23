#=require select2
#=require utility_admin/modelinker
modelinker = new Modelinker
presurveys = {}

survey_helper = (survey)->

  """<input id="1914171187672764" class="modelinker " data-mid="1914171187672764" value="0" data-linker="attr.522884c0eb0e5b0845000004.ary_0" type="checkbox">"""
  question_html = ""
  for question in survey.email_questions
    inner_html = modelinker.generate
      type: "input"
      value: question._id
      linker: "conditions.survey.#{question._id}"
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

question_helper = (question)->

  item_html = ""
  for item in question.issue.items
    inner_html = modelinker.generate
      type: "input"
      value: question._id
      linker: "conditions.survey.#{question._id}"
      html_attr:
        type: "checkbox"
    question_html += """
      <label class="checkbox">
        #{inner_html}#{item.content.text}
      </label>
    """
  wrapper = """
  <p>#{question.content.text}</p>
  #{question_html}
  """

question_selector_helper = (questions, iswrap = false) ->
  questions_html = ""
  for question in questions
    questions_html += """
      <option value="#{question._id}">#{question.content.text}</option>
    """
  return question if !iswrap
  wrapper = """
    <select id="question_selector_#{$(".question_selector").length}" class="question_selector">
      #{questions_html}
    </select>
  """

# refresh_question_selectors = () ->
#   for questions in 
    # ...
  

"""
  
<p>1. 这里是一个问题 </p>
<label class="checkbox">
  <input id="1914171187672764" class="modelinker " data-mid="1914171187672764" value="0" data-linker="attr.522884c0eb0e5b0845000004.ary_0" type="checkbox">答案 1 
</label>
<label class="checkbox">
  <input id="1914171187672764" class="modelinker " data-mid="1914171187672764" value="0" data-linker="attr.522884c0eb0e5b0845000004.ary_0" type="checkbox">答案 2
</label>
<label class="checkbox">
  <input id="1914171187672764" class="modelinker " data-mid="1914171187672764" value="0" data-linker="attr.522884c0eb0e5b0845000004.ary_0" type="checkbox">答案 3
</label>
<label class="checkbox">
  <input id="1914171187672764" class="modelinker " data-mid="1914171187672764" value="0" data-linker="attr.522884c0eb0e5b0845000004.ary_0" type="checkbox"><i>模糊匹配</i>
</label>
"""

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
      url: "prequestions"
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
    $(".question_placeholder").append(question_selector_helper(survey.choice_questions, true))
    $("#question_selector_#{$('.question_selector').length-1}").select2()

    
)



