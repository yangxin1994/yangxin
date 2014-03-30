# encoding: utf-8
class SurveyTask < Survey

  include Mongoid::Document

  # field :title, :type => String, default: "调查问卷主标题"
  # field :description, :type => String, default: "调查问卷描述"
  # # can be 1 (closed), 2 (published), 4 (deleted)
  # field :status, :type => Integer, default: 2
  field :identifier, :type => String
  field :origin_url, :type => String
  field :origin_route, :type => String

  def get_encoded_url(user = nil)
    encode_id = Base64.encode64("#{identifier}|#{scheme_id}|#{user.try(:id)}|")
    "#{origin_route}#{encode_id}?s=true"
  end


  def excute_sample_data(user=nil)
    answer = answer_by_sample(user)
    self['answer_status'] = answer.try(:status) || 0
    self['answer_reject_type'] = answer.try(:reject_type) || 0
    self['reward_type_info'] = RewardScheme.first_reward_by_survey(self.scheme_id)
    self["encoded_url"] = get_encoded_url(user)
    return self
  end
  
end