//=require jquery
//=require pages/admin/common/od_popup
class Column
  constructor: (title) ->
    @title = title
    @id = "column_#{Date.now() + Math.round(Math.random()*1000)}"
    @article_template = =>
      return {
        id:         "article_#{Date.now() + Math.round(Math.random()*1000)}"
        column_id:  this.id
        order:      0
        caption:    "请输入标题"
        time:       "2013.01.01"
        url:        "http://www.oopsdata.com/"
        right:      true
        abstract:   "这里是一段文字摘要, 最好不要少于150字, 也不要多于500字. 就像这样:
              最好不要少于150字, 也不要多于500字. 就像这样:
              最好不要少于150字, 也不要多于500字. 就像这样:
              最好不要少于150字, 也不要多于500字. 就像这样:
              最好不要少于150字, 也不要多于500字. 就像这样:
              最好不要少于150字, 也不要多于500字. 就像这样:
        "
        image_url:  "http://quill.oopsdata.com:3000/assets/zine/1.png"
      }
    @editing_article = new @article_template()
    @articles = [@editing_article]

  new_atricle: ->
    tmp_article = new this.article_template()
    tmp_article.id = "article_#{Date.now() + Math.round(Math.random()*1000)}"
    tmp_article

  add_atricle: (time, url, right, abstract, image_url)->
    new_article           = new this.article_template()
    new_article.id        = "article_#{Date.now() + Math.round(Math.random()*1000)}"
    new_article.order     = this.articles.length
    new_article.time      = time
    new_article.url       = url
    new_article.right     = right
    new_article.abstract  = abstract
    new_article.image_url = image_url
    new_article.column_id = this.id
    new_article
    this.articles.push new_article
    new_article

  commit_article: (tmp_article)->
    i = 0
    for article in this.articles
      if article.id == tmp_article.id
        return this.articles[i] = tmp_article
      i += 1
    this.articles.push tmp_article
    tmp_article

  get_article: (article_id)->
    for article in this.articles
      return article if article.id == article_id

  present: ->
    ats = []
    for article in this.articles
      at = {}
      at.id        = article.id
      at.column_id = article.column_id
      at.order     = article.order
      at.caption   = article.caption
      at.time      = article.time
      at.url       = article.url
      at.right     = article.right
      at.abstract  = article.abstract
      at.image_url = article.image_url
      ats.push at

    pst = {
      id:       this.id
      title:    this.title
      articles: ats
    }
    pst

class Newsletter
  constructor: () ->
    @status     = 0
    @title      = "优数动态 | 优数"
    @columns    = []
    @columns.push(new Column("优数动态"))
    @columns.push(new Column("产品动态"))
    @oops_column = @columns[0]
    @pdct_column = @columns[1]
  # 下面是 column 的操作


  column_new: ->
    $("#column-create-dlg").dialog("open")

  get_column: (column_id)->
    for column in this.columns
      return column if column.id == column_id

  add_column_btn: (column)->
    $("#column-new-btn").before("<button data=\"#{column.id}\" class=\"column-btn od-button\">#{column.title}</button>")

  column_create: (title)->
    tmp_column = new Column(title)
    $.ajax
      url:   '/admin/newsletters/column'
      type:  'POST'
      data:  {
        column:
          tmp_column.present()
      }
      success: (ret)=>
        this.columns.push(tmp_column)
        this.add_column_btn(tmp_column)
        $('.column_placeholder').before(ret)

  column_update: ->
    column = this.get_column($("#column-id").val())
    column.title = $("#column-title-edit").val()
    $("##{column.id} > h3").text(column.title)
    column

  column_delete: ->
    column_id = $("#column-id").val()
    id_delete = false
    i = 0
    for column in this.columns
      if column
        if column.id == column_id
          this.columns.splice(i, 1)
          is_delete = true
      i+=1
    if is_delete
      $("##{column_id}").remove()


  # 下面是 article 的操作
  refresh_article_list: (articles)->
    $("#article-list").empty()
    for article in articles
      $("#article-list").append("<option value=\"#{article.id}\">#{article.caption}</option>")

  refresh_article_edit: (article)->
    $("#article-id").val(article.id)
    $("#article-caption").val(article.caption)
    $("#article-time").val(article.time)
    $("#article-url").val(article.url)
    $("#article-image_url").val(article.image_url)
    if article.right.toString() == 'true'
      $("#article-right").prop("checked", true)
    else
      $("#article-right").prop("checked", false)
    $("#article-abstract").val(article.abstract)

  assign_article:  ->
    column = this.get_column($("#column-id").val())
    tmp_article = column.editing_article
    tmp_article.caption    = $("#article-caption").val()
    tmp_article.time       = $("#article-time").val()
    tmp_article.url        = $("#article-url").val()
    if $("#article-right").prop("checked")
      tmp_article.right = true
    else
      tmp_article.right = false
    tmp_article.abstract   = $("#article-abstract").val()
    tmp_article.image_url  = $("#article-image_url").val()
    tmp_article

  article_new: (column)->
    # 冻结按钮
    column ||= this.get_column($("#column-id").val())
    column.editing_article = column.new_atricle()
    console.log column.editing_article
    this.refresh_article_edit(column.editing_article)

  get_article: (article_id) ->
    for column in this.columns
      article = column.get_article(article_id)
      return article if article

  article_create: ->
    tmp_article = this.assign_article()
    column = this.get_column(tmp_article.column_id)
    type = "article"
    if column.id == newsletter.pdct_column.id
      type = "product_news"
    $("#article-edit-div").hide()
    $.ajax
      url:   "/admin/newsletters/#{type}"
      type:  'POST'
      data:  {
        article:
          id:        tmp_article.id
          column_id: tmp_article.column_id
          order:     tmp_article.order
          caption:   tmp_article.caption
          time:      tmp_article.time
          url:       tmp_article.url
          right:     tmp_article.right
          abstract:  tmp_article.abstract
          image_url: tmp_article.image_url
      }
      success: (ret)->
        column.commit_article(tmp_article)
        $("##{column.id} > .article_placeholder").before(ret)

  article_edit: ->
    # 冻结按钮
    article = this.get_article($("#article-list").val())
    this.get_column(article.column_id).editing_article = article
    this.refresh_article_edit(article)
    $("#article-edit-div").show()

  article_update: ->
    tmp_article = this.assign_article()
    column = this.get_column(tmp_article.column_id)
    type = "article"
    if column.id == newsletter.pdct_column.id
      type = "product_news"
    $("#article-edit-div").hide()
    $.ajax
      url:   "/admin/newsletters/#{type}"
      type:  'POST'
      asyn:  false
      data:  {
        article :
          id:        tmp_article.id
          column_id: tmp_article.column_id
          order:     tmp_article.order
          caption:   tmp_article.caption
          time:      tmp_article.time
          url:       tmp_article.url
          right:     tmp_article.right
          abstract:  tmp_article.abstract
          image_url: tmp_article.image_url
      }
      success: (ret)->
        column.commit_article(tmp_article)
        $("##{tmp_article.id}").before("<div id=\"#{tmp_article.id}_placeholder\"></div>")
        $("##{tmp_article.id}").remove()
        $("##{tmp_article.id}_placeholder").before(ret)
        $("##{tmp_article.id}_placeholder").remove()

  article_delete: ->
    article_id = $("#article-list").val()
    id_delete = false
    i = 0
    for column in this.columns
      i = 0
      for article in column.articles
        if article
          if article.id == article_id
            column.articles.splice(i, 1)
            is_delete = true
        i+=1
    if is_delete
      $("##{article_id}").remove()
      $("#column-edit-dlg").dialog("close");

  oopsnews_new: ->
    this.article_new(oops_column)

  oopsnews_create: ->


  oopsnews_edit: ->

  update: ->
    this.title = d_c.newsletter_title_edit.val()

  present: ->
    pst = {
      columns: [],
      title:   this.title
      status:  this.status
    }
    for column in this.columns
      pst.columns.push column.present()
    pst

  create: ->
    $.ajax
      url:   '/admin/newsletters'
      type:  'POST'
      async:   false
      data:  {
        newsletter : this.present()
      }
      success: (ret)=>
        this.obj_id = ret.value._id
        console.log ret

  destroy: ->
    $.ajax
      url:   "/admin/newsletters/#{newsletter.obj_id}"
      type:  'DELETE'
      data:  {
      }
      success: (ret)->
        if ret.success
          alert "删除成功"
          window.location = '/admin/newsletters'
        else
          alert "删除失败:" + ret.value.error_code

  commit: ->
    $.ajax
      url:   "/admin/newsletters/#{this.obj_id}"
      type:  'PUT'
      async:   false
      data:  {
        newsletter : this.present()
      }
      success: (ret)->
        console.log ret

  deliver: ->
    content = $(".content")[0].outerHTML
    $.ajax
      url:   "/admin/newsletters/#{newsletter.obj_id}/deliver"
      type:  'POST'
      data:  {
        content: content
      }
      success: (ret)->
        if ret.success
          alert "发送已处理"
        else
          alert "发送失败:" + ret.value.error_code

window.Column = Column
window.newsletter = new Newsletter



