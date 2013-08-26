$ ->
  $('#survey_select a').click ->
    $('#survey_id').val($(this).attr('href').split('-')[1])

  $("#survey_select a[href='#survey-#{$('#survey_id').val()}']").click()

  $('#agent_select a').click ->
    $('#agent_id').val($(this).attr('href').split('-')[1])

  $("#agent_select a[href='#agent-#{$('#agent_id').val()}']").click()  

  $("#agent_form").validate
    rules:
      'agent[survey_id]': 
          required: true
      'agent[agent_id]': 
          required: true
      'agent[count]':
          required: true
          digits: true

    messages:
      'agent[survey_id]': 
          required: "必须选择一份问卷"
      'agent[agent_id]': 
          required:"必须选择一个代理"
      'agent[count]':
          required: "必须填写回收数量"
          digits: "回收数量是一个整数"
