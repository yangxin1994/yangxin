# encoding: utf-8
class PointLog < Log
	field :type, :type => Integer, :default => 8
	field :amount, :type => Integer
	field :reason, :type => Integer #1（回答问卷），2（推广问卷），4（礼品兑换）， 8（管理员操作）,16(处罚操作)	
	field :survey_title, :type => String
	field :survey_id, :type => String
	field :gift_name, :type => String
	field :remark, :type => String

	ANSWER = 1
	SPREAD = 2
	REDEEM = 4
	ADMIN_OPERATE = 8
	PUNISH = 16
end
