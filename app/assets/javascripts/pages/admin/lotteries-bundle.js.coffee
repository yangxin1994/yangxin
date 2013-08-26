$(->

  prize_ids = $('#prize_ids').val().split(',')
  is_prize_hidden = true
  is_edit_prize = false
  prize_icon_index = $('#prize_icons li').length - 1
  prizes = []
  is_prize_locked = false
  temp_prize = {}
  temp_img_src = ""
  temp_self_index = 0
  # 添加验证
  $("#lottery_form").validationEngine();
  # 图片预览

  init_prizes = () ->
    temp_prizes = []
    $.each window.l_prizes || [], (index, prize) ->
      tp = new Object()
      tp.id = prize._id
      tp.is_new = false
      tp.name = prize.name
      tp.type = prize.type
      tp.surplus = prize.surplus
      tp.photo = prize.photo_src
      tp.description = prize.description
      tp.self_index = index
      console.log tp
      temp_prizes.push tp
    temp_prizes
  prizes = init_prizes()
  $.each prizes, (i,o) ->
    console.log i
    console.log o

  show_photo = (upload_id, img_id) ->
    if $("##{upload_id}").val() != ""
      $("##{img_id}").attr "src", window.URL.createObjectURL(document.getElementById("#{upload_id}").files.item(0))
  # 添加 img input

  make_img_input = (upload_id, img_id) ->
    formData = new FormData()
    action = '/admin/materials';
    fileInput = document.getElementById('prize_photo');
    file = fileInput.files[0];
    formData.append('our-file', file);
    sendXHRequest(formData, action);

  sendXHRequest = (formData, uri) ->
    xhr = new XMLHttpRequest()
    xhr.open('POST', uri, true);
    xhr.onreadystatechange = () ->
      $("#prize_photo_src").attr 'src', xhr.responseText
      temp_img_src = xhr.responseText
      console.log xhr.responseText
    xhr.send(formData);

  # 生成奖品 icon
  prize_icon = (prize) ->
    img_src = "/assets/images/img.png"
    img_src = $("#prize_photo_src").attr("src") if $("#prize_photo_src").attr("src").length != 0
    str = "
      <li id=\"prize_icon_#{prize_icon_index}\" _id=\"#{prize_icon_index}\" style=\"display: none\">
        <a href=\"##{prize_icon_index}\" title=\"#{prize.name}\" class=\"btn-prize_icon\" >
          <img src=\"#{img_src}\" alt=\"\" id=\"prize_icon_src_#{prize_icon_index}\" width=\"100%\" />
        </a>
        <div class=\"actions\">
          <a href=\"##{prize_icon_index}\" title=\"\" class=\"btn-edit-prize\"><img src=\"/assets/images/edit.png\" alt=\"\" /></a>
          <a href=\"##{prize_icon_index}\" title=\"\" class=\"btn-delete-prize\"><img src=\"/assets/images/delete.png\" alt=\"\" /></a>
        </div>
      </li>
    "
    str

  # 奖品属性赋值
  get_prize_attr = ->
    prize =
      id: temp_prize.id
      is_new: temp_prize.is_new
      name: $('#prize_name').val()
      type: $('#prize_type').val()
      surplus: $('#prize_surplus').val()
      #photo: document.getElementById("prize_photo").files.item(0)
      # photo: temp_img_src || temp_prize.photo
      photo: $("#prize_photo_src").attr "src"
      self_index: temp_self_index
      description: $('#prize_desc').val()
      # photo_src: $("#prize_photo_src").attr "src"
    prize

  clear_prize_form = ->
    $.each $('.prize-input'), (index, prize) ->
      $(prize).val null
    $("#prize_photo_src").attr "src", ""

  add_prize_icon = (prize) ->
    str = prize_icon prize
    $('#prize_icons').append str
    $("#prize_icon_#{prize_icon_index}").fadeIn 300

  edit_prize_icon = (prize) ->
    str = prize_icon prize

  add_prize = (prize) ->
    prize_icon_index += 1
    prize.is_new = true
    prize.self_index = prize_icon_index
    prizes.push prize
    add_prize_icon prize
    clear_prize_form()

  # 填充 prize form
  set_prize_attr = (prize) ->
    temp_prize = prize
    $('#prize_name').val prize.name
    $('#prize_type').val prize.type
    $('#prize_surplus').val prize.surplus
    $('#prize_photo_src').attr 'src', prize.photo
    $('#prize_desc').val prize.description

  edit_prize = (prize) ->
    prizes[prize.self_index] = prize
    $($('.btn-prize_icon img')[prize.self_index]).attr('src', prize.photo)
    is_edit_prize = !is_edit_prize
    clear_prize_form()

  delete_prize = (prize_index) ->
    console.log prize_index
    console.log prizes[prize_index]
    prize = prizes[prize_index]
    # prize_icon_index -= 1
    prize.is_deleted = true
    $("#prize_icon_#{prize_index}").fadeOut 300
  # Post 奖品
  # add_prizes_to = (lottery) ->
  #   $.post

  ######################## 事件绑定  ##########################

  # 添加奖品
  $('#btn_prize_form').click ->
    # $('')
    # 验证
    $('#prize_form').slideToggle 'slow', ->
      if !is_prize_hidden
        prize = get_prize_attr()
        # img_src = $("#prize_photo_src").attr "src"
        if is_edit_prize
          edit_prize(prize)
        else
          add_prize(prize)
        is_prize_locked = false
      else
        is_prize_locked = true
      is_prize_hidden = !is_prize_hidden
    console.log prizes
    return false

  # 绑定prize编辑事件
  $(".pics ul").delegate 'li', 'hover',
    -> $(this).children(".actions").show("fade", 200),
    -> $(this).children(".actions").hide("fade", 200)

  # 绑定"编辑奖品"
  $('#prize_icons').delegate '.btn-prize_icon','click', ->
    return false if is_prize_locked
    prize_index = $(this).attr("href").replace(/#/,'')
    $('#prize_form').slideToggle 'slow', ->
      is_prize_hidden = !is_prize_hidden
      set_prize_attr prizes[prize_index]
      temp_self_index = prize_index
      is_edit_prize = !is_edit_prize
      is_prize_locked = true
    return false

  # 绑定"删除奖品"
  $('#prize_icons').delegate '.btn-delete-prize', 'click', ->
    delete_prize $(this).attr("href").replace(/#/,'')
    return false

  # 绑定"编辑奖品"
  $('#prize_icons').delegate '.btn-edit-prize', 'click', ->
    return false if is_prize_locked
    prize_index = $(this).attr("href").replace(/#/,'')
    $('#prize_form').slideToggle 'slow', ->
      is_prize_hidden = !is_prize_hidden
      set_prize_attr prizes[prize_index]
      temp_self_index = prize_index
      is_edit_prize = !is_edit_prize
      is_prize_locked = true
    return false

  $('.pics ul').delegate 'li', 'mouseover', ->
    $(this).children(".actions").show("fade", 200)
  $('.pics ul').delegate 'li', 'mouseout', ->
    $(this).children(".actions").hide("fade", 200)

  # 上传图片预览
  $('#lottery_photo').change ->
    show_photo "lottery_photo", "lottery_photo_src"
  # 上传prize图片预览
  $('#prize_photo').change ->
    make_img_input "prize_photo", "prize_photo_src"

  $('#submit_lottery').click (retval) ->
    $.post '/admin/prizes', {prizes: prizes}, (retval) ->
      console.log retval
      if retval
        $('#prize_ids').val(retval.value)
        console.log $('#prize_ids').val()
        $('#lottery_form').submit()

        # 设置 is_new = false
        # 设置 _id
        #
  $('#cancel_lottery').click (retval) ->
    $.post '/admin/prizes', {prizes: prizes}, (retval) ->
      if retval
        window.location.href = "/admin/lotteries"
  return true
)
