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

$(()->
  $("#survey_selector").select2()
  $("#question_selector_0").select2()

  $("#survey_selector").change (e)->
    $this = $(this)
    survey =
      title: this.selectedOptions[0].innerHTML
      _id: $this.val()

    $.ajax
      method: "GET"
      url: "prequestions"
      async: false
      data: 
        survey_ids: survey._id
        stype: "4|6"
      success: (ret)->
        if ret.success
          presurveys[survey._id] = ret.value
          survey.email_questions = ret.value.questions
        else
          alert_msg.show('error', "系统繁忙请稍后再试 (╯‵□′)╯︵┻━┻")

      error: ->
        alert_msg.show('error', "系统繁忙请稍后再试 (╯‵□′)╯︵┻━┻")

    $("#survey_list").append(survey_helper(survey))

    
  $("#quesiton_pannel").on "change", ".question_selector", ->
    console.log this.value

)



