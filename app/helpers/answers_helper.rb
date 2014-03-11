# encoding: utf-8

module AnswersHelper

  def answer_type_tag(status, is_agent = false)
    tag = ""
    case status.to_i
    when Answer::EDIT
      tag = '正在答题'
    when Answer::REJECT
      tag = '已拒绝'
    when Answer::UNDER_REVIEW
      if is_agent
        tag = '等待管理员审核'
      else
        tag = '待审核'
      end
    when Answer::UNDER_AGENT_REVIEW
      if is_agent
        tag = '待审核'
      else
        tag = '待代理审核'
      end
    when Answer::REDO
      tag = '等待重答'
    when Answer::FINISH
      tag = '通过审核'
    end
    tag.html_safe
  end
end
