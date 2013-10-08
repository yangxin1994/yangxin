# encoding: utf-8
module AgentsHelper

  def agent_status_tag(status)
    case status.to_i
    when 1
      "正常"
    when 
      "已删除"
    when 4
      ""
    end
  end
end
