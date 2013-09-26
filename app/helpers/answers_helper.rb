# encoding: utf-8

module AnswersHelper

  def answer_type_tag(status)
    tag = ""
    case status.to_i
    when Answer::EDIT
      tag = '正在答题'
    when Answer::REJECT
      tag = '已拒绝'
    when Answer::UNDER_REVIEW
      tag = '待审核'
    when Answer::UNDER_AGENT_REVIEW
      tag = '待代理审核'
    when Answer::REDO
      tag = '等待重答'
    when Answer::FINISH
      tag = '通过审核'
    end
    tag.html_safe
  end
end
