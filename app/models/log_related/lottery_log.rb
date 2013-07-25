# encoding: utf-8
class LotteryLog < Log
	field :type, :type => Integer,:default => 2
	field :result, :type => Boolean, :default => false #表示是否抽中
  field :order_id, :type => String
  field :prize_id, :type => String
  field :prize_name, :type => String
  field :survey_id, :type => String
  field :survey_title, :type => String


  def self.find_lottery_logs(answer_id)
  	answer = Answer.find_by_id(answer_id)
  	survey_id = answer.survey.id
  	return self.where(:survey_id => survey_id)
  end
end
