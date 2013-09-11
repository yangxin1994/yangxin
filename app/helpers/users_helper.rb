# encoding: utf-8
# already tidied up

module UsersHelper

  def point_log_status(status)
    case status
    when 0
      "管理员操作"
    when 1
      "邀请用户"
    when 2
      "填写问卷"
    when 3
      "推广问卷"
    when 4
      "兑换礼品"
    when 5
      "系统返还"
    else
      status
    end
  end
end
