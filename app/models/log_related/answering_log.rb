# encoding: utf-8
class AnsweringLog < Log

	field :type, :type => Integer, :default => 1
	field :survey_id, :type => String
	field :scheme_id, :type => String
	field :survey_title, :type => String
	field :reward_type, :type => Integer  #type(0 免费, 1 表示话费，2表示支付宝转账，4表示优币，8表示抽奖，16表示发放集分宝) 
	field :amount, :type => Integer #表示奖励的数量 

end