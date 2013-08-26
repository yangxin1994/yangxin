###
jquery.qeditor
==============

This is a simple WYSIWYG editor with jQuery.

## Author:

    Jason Lee <huacnlee@gmail.com>

## Requirements:

    [jQuery](http://jquery.com)
    (Font-Awesome)[http://fortawesome.github.io/Font-Awesome/] - Toolbar icons

## Usage:

    $("textarea").qeditor();

and then you need filt the html tags,attributes in you content page.
In Rails application, you can use like this:

    <%= sanitize(@post.body,:tags => %w(strong b i u strike ol ul li address blockquote pre code br div p), :attributes => %w(src)) %>
###

QEDITOR_TOOLBAR_HTML = """
<div class="qeditor_toolbar">
  <a href="#" onclick="return QEditor.action(this,'bold');" class="qe-bold"><i class="icon-bold" title="Bold"></i></a> 
  <a href="#" onclick="return QEditor.action(this,'italic');" class="qe-italic"><i class="icon-italic" title="Italic"></i></a> 
  <a href="#" onclick="return QEditor.action(this,'underline');" class="qe-underline"><i class="icon-italic" title="Underline"></i></a> 
  <a href="#" onclick="return QEditor.action(this,'strikethrough');" class="qe-strikethrough"><i class="icon-italic" title="Strike-through"></i></a>		 
  <span class="vline"></span>
  <span class="qe-icon qe-heading">
    <ul class="qe-menu">
      <li><a href="#" data-name="h1" class="qe-h1">Heading 1</a></li>
      <li><a href="#" data-name="h2" class="qe-h2">Heading 2</a></li>
      <li><a href="#" data-name="h3" class="qe-h3">Heading 3</a></li>
      <li><a href="#" data-name="h4" class="qe-h4">Heading 4</a></li>
      <li><a href="#" data-name="h5" class="qe-h5">Heading 5</a></li>
      <li><a href="#" data-name="h6" class="qe-h6">Heading 6</a></li>
      <li class="qe-hline"></li>
      <li><a href="#" data-name="p" class="qe-p">Paragraph</a></li>
    </ul>
    <span class="icon icon-font"></span>
  </span>
  <span class="vline"></span>
  <a href="#" onclick="return QEditor.action(this,'insertorderedlist');" class="qe-ol"><i class="icon-th-list" title="Insert Ordered-list"></i></a> 
  <a href="#" onclick="return QEditor.action(this,'insertunorderedlist');" class="qe-ul"><i class="icon-th-list" title="Insert Unordered-list"></i></a> 
  <a href="#" onclick="return QEditor.action(this,'indent')" class="qe-indent"><i class="icon-indent-right" title="Indent"></i></a> 
  <a href="#" onclick="return QEditor.action(this,'outdent')" class="qe-outdent"><i class="icon-indent-left" title="Outdent"></i></a> 
  <span class="vline"></span> 
  <a href="#" onclick="return QEditor.action(this,'insertHorizontalRule');" class="qe-hr"><i class="icon-minus" title="Insert Horizontal Rule"></i></a> 
  <a href="#" onclick="return QEditor.action(this,'formatBlock','blockquote');" class="qe-blockquote"><i class="icon-minus" title="Blockquote"></i></a> 
  <a href="#" onclick="return QEditor.action(this,'formatBlock','pre');" class="qe-pre"><i class="icon-minus" title="Pre"></i></a> 
  <a href="#" onclick="return QEditor.action(this,'createLink');" class="qe-link"><i class="icon-minus" title="Create Link" title="Create Link"></i></a> 
  <a href="#" onclick="return QEditor.action(this,'insertimage');" class="qe-image"><i class="icon-picture" title="Insert Image"></i></a> 
  <a href="#" onclick="return QEditor.toggleFullScreen(this);" class="qe-fullscreen pull-right"><i class="icon-fullscreen" title="Toggle Fullscreen"></i></a> 
</div>
"""
QEDITOR_ALLOW_TAGS_ON_PASTE = "div,p,ul,ol,li,hr,br,b,strong,i,em,img,h2,h3,h4,h5,h6,h7"
QEDITOR_DISABLE_ATTRIBUTES_ON_PASTE = ["style","class","id","name","width","height"]

window.QEditor = 
  action : (el,a,p) ->
    editor = $(".qeditor_preview",$(el).parent().parent())
    editor.find(".qeditor_placeholder").remove()
    editor.focus()
    p = false if p == null
    
    if a == "createLink"
      p = prompt("Type URL:")
      return false if p.trim().length == 0
    else if a == "insertimage"
      p = prompt("Image URL:")
      return false if p.trim().length == 0
    
    document.execCommand(a, false, p)
    editor.change()
    false
  
  prompt : (title) ->
    val = prompt(title)
    if val
      return val
    else
      return false
  
  toggleFullScreen : (el) ->
    border = $(el).parent().parent()
    if border.data("qe-fullscreen") == "1"
      QEditor.exitFullScreen()
    else
      QEditor.enterFullScreen(border)

    false
  
  enterFullScreen : (border) ->
    border.data("qe-fullscreen","1")
          .addClass("qeditor_fullscreen")
    border.find(".qeditor_preview").focus()
    border.find(".qe-fullscreen span").attr("class","icon-resize-small")
  
  exitFullScreen : () ->
    $(".qeditor_border").removeClass("qeditor_fullscreen")
                        .data("qe-fullscreen","0")
                        .find(".qe-fullscreen span").attr("class","icon-fullscreen")
    
  getCurrentContainerNode : () ->
    if window.getSelection
      node = window.getSelection().anchorNode
      containerNode = if node.nodeType == 3 then node.parentNode else node
    return containerNode
    
  version : ->
    "0.1.1"

do ($=jQuery)->
  $.fn.qeditor = (options) ->
    this.each ->
      obj = $(this)
      obj.addClass("qeditor")
      editor = $('<div class="qeditor_preview clearfix" contentEditable="true"></div>')
      placeholder = $('<div class="qeditor_placeholder"></div>')
    
      $(document).keyup (e) ->
        QEditor.exitFullScreen() if e.keyCode == 27
      
      # use <p> tag on enter by default
      document.execCommand('defaultParagraphSeparator', false, 'p')
    
      currentVal = obj.val()
      # if currentVal.trim().lenth == 0
        # TODO: default value need in paragraph
        # currentVal = "<p></p>"
    
      editor.html(currentVal)
      editor.addClass(obj.attr("class"))
      obj.after(editor)
    
      # add place holder
      placeholder.text(obj.attr("placeholder"))
      editor.attr("placeholder",obj.attr("placeholder"))
      editor.append(placeholder)
      editor.focusin ->
        $(this).find(".qeditor_placeholder").remove()
      editor.blur ->
        t = $(this)
        if t.html().length == 0 or t.html() == "<br>" or t.html() == "<p></p>" 
          $(this).html('<div class="qeditor_placeholder">' + $(this).attr("placeholder") + '</div>' )
    
      # put value to origin textare when QEditor has changed value
      editor.change ->
        pobj = $(this);
        t = pobj.parent().find('.qeditor')
        t.val(pobj.html())
    
      # watch pasite event, to remove unsafe html tag, attributes
      editor.on "paste", ->
        txt = $(this)
        setTimeout ->
          els = txt.find("*")
          for attrName in QEDITOR_DISABLE_ATTRIBUTES_ON_PASTE
            els.removeAttr(attrName)
          els.find(":not(#{QEDITOR_ALLOW_TAGS_ON_PASTE})").contents().unwrap()
          txt.change()
          true
        ,100
    
      # attach change event on editor keyup
      editor.keyup (e) ->
        $(this).change()
      
      editor.on "click", (e) ->
        e.stopPropagation()
      
      editor.keydown (e) ->
        node = QEditor.getCurrentContainerNode()
        nodeName = ""
        if node and node.nodeName
          nodeName = node.nodeName.toLowerCase()
        if e.keyCode == 13 && !(e.shiftKey or e.ctrlKey)
          if nodeName == "blockquote" or nodeName == "pre"
            e.stopPropagation()
            document.execCommand('InsertParagraph',false)
            document.execCommand("formatBlock",false,"p")
            document.execCommand('outdent',false)
            return false             
          
      
      obj.hide()
      obj.wrap('<div class="qeditor_border"></div>')
      obj.after(editor)
    
      # render toolbar & binding events
      toolbar = $(QEDITOR_TOOLBAR_HTML)
      qe_heading = toolbar.find(".qe-heading")
      qe_heading.mouseenter ->
        $(this).addClass("hover")
        $(this).find(".qe-menu").show()
      qe_heading.mouseleave ->
        $(this).removeClass("hover")
        $(this).find(".qe-menu").hide()
      toolbar.find(".qe-heading .qe-menu a").click ->
        link = $(this)
        link.parent().parent().hide()
        QEditor.action(this,"formatBlock",link.data("name"))
        return false
      editor.before(toolbar)