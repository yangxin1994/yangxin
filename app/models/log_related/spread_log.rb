# encoding: utf-8
# already tidied up
class SpreadLog < Log
    field :type, :type => Integer, :default => 32
    field :survey_id, :type => String
    field :survey_title, :type => String
    field :reward_type, :type => Integer  #type(0 免费, 1 表示话费，2表示支付宝转账，4表示积分，8表示抽奖，16表示发放集分宝) 
    field :amount, :type => Integer #表示奖励的数量
end
