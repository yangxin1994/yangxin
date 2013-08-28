//=require jquery-ui.min

# 这里是预置的事件绑定
window.d_c = new ()->
  {
    column_create_dlg:     $("#column-create-dlg")
    column_edit_dlg:       $("#column-edit-dlg")
    newsletter_edit_dlg:   $("#newsletter-edit-dlg")
    newsletter_title_edit: $("#newsletter-title-edit")

    column_new_btn:       $("#column-new-btn")

    column_title_new:     $("#column-title-new")
    column_title_edit:    $("#column-title-edit")

    column_id:            $("#column-id")

    article_list:         $("#article-list")
    article_edit_div:     $("#article-edit-div")

  }

$(".zine").on 'click', 'a', ->
  return false if !confirm("确定执行页面跳转吗?(未经保存的改动将会丢失)")

$("#column-create-dlg").dialog({ autoOpen: false })
d_c.column_edit_dlg.dialog({
  autoOpen: false,
  height: 272,
  width: 500
 })
d_c.newsletter_edit_dlg.dialog({ autoOpen: false })

$("#article-list").change ()->
  $("#article-edit-div").hide()

$("#newsletter-edit-btn").click ->
  d_c.newsletter_title_edit.val(newsletter.title)
  d_c.newsletter_edit_dlg.dialog("open")

$("#column-new-btn").click ()->
  $("#column-title-new").val('')
  newsletter.column_new()

$("#edit-pad").on "click", ".column-btn", ->
  column = newsletter.get_column($(this).attr('data'))
  $("#column-title-edit").val(column.title)
  $("#column-edit-pad").show()
  $("#image-edit-pad").show()
  $("#column-id").val(column.id)
  newsletter.refresh_article_list(column.articles)
  # $("#column-title-edit").val(column.title)
  d_c.column_edit_dlg.dialog("open")

$("#oops-btn").click ()->
  $("#column-id").val(newsletter.oops_column.id)
  $("#column-edit-pad").hide()
  $("#image-edit-pad").show()
  newsletter.refresh_article_list(newsletter.oops_column.articles)
  d_c.column_edit_dlg.dialog("open")

$("#pdct-btn").click ()->
  $("#column-id").val(newsletter.pdct_column.id)
  $("#column-edit-pad").hide()
  $("#image-edit-pad").hide()
  newsletter.refresh_article_list(newsletter.pdct_column.articles)
  d_c.column_edit_dlg.dialog("open")

$("#column-update-btn").click ()->
  column = newsletter.column_update()
  d_c.column_edit_dlg.dialog("close")
  for btn in $(".column-btn")
    if $(btn).attr("data") == $("#column-id").val()
      console.log btn
      $(btn).text(column.title)
  false

$("#column-delete-btn").click ()->
  column_id = $("#column-id").val()
  newsletter.column_delete()
  d_c.column_edit_dlg.dialog("close")
  for btn in $(".column-btn")
    if $(btn).attr("data") == column_id
      $(btn).remove()
  false

# 这里是对栏目的操作
$("#column-create-btn").click ()->
  $("#column-create-dlg").dialog( "close" );
  title = $('#column-title-new').val() || "新栏目"
  $('#column-title-edit').val('')
  newsletter.column_create(title)

$("#article-edit-btn").click ->
  $("#article-update-btn").show()
  $("#article-create-btn").hide()
  newsletter.article_edit()
  d_c.column_edit_dlg.dialog(height: 720)
  false

$("#article-delete-btn").click ->
  $("#article-edit-div").hide()
  newsletter.article_delete()
  false

$("#article-new-btn").click ->
  $("#article-create-btn").show()
  $("#article-update-btn").hide()
  newsletter.article_new()
  $("#article-edit-div").show()
  d_c.column_edit_dlg.dialog(height: 720)
  false

$("#article-create-btn").click ->
  newsletter.article_create()
  d_c.column_edit_dlg.dialog(height: 272).dialog("close")
  false

$("#article-update-btn").click ->
  newsletter.article_update()
  d_c.column_edit_dlg.dialog(height: 272).dialog("close")
  false
# 以下是对整个杂志的操作
$('#newsletter-update-btn').click ->
  newsletter.update()
  d_c.newsletter_edit_dlg.dialog("close")
  false

$("#newsletter-test-btn").click ->
  test_e = prompt("请输入测试邮箱,多个邮箱请用逗号分隔","")
  if test_e
    newsletter.commit()
    if newsletter.obj_id
      content = $(".content")[0].outerHTML
      $.ajax
        url:   "/admin/newsletters/#{newsletter.obj_id}/test"
        type:  'POST'
        data:  {
          email: test_e
          content: content
        }
        success: (ret)->
          if ret.success
            alert "发送已处理"
          else
            alert "发送失败:" + ret.value.error_code
    else
      alert "出现错误,请刷新重试"
  false

$("#newsletter-deliver-btn").click ->
  newsletter.commit()
  # 去除空标签
  if confirm("是否开始向订阅者群发电子杂志？请确保电子杂志内容符合预期。点击确定开始发送，点击取消重新检查。")
    newsletter.deliver()
  false

$("#newsletter-return-btn").click ->
  window.location = '/admin/newsletters'
  false

$("#newsletter-delete-btn").click ->
  if confirm("确定删除吗?")
    newsletter.destroy()
  false

$("#newsletter-save-btn").click ->
  newsletter.commit()
  alert("保存成功")
  false

$("#newsletter-create-btn").click ->
  newsletter.create()
  if newsletter.obj_id
    $("#newsletter-test-btn").show()
    $("#newsletter-deliver-btn").show()
    $("#newsletter-delete-btn").show()
  else
    alert "保存失败"
  false

