# encoding: utf-8
class PointLog < Log
	field :type, :type => Integer, :default => 8
	field :amount, :type => Integer
	field :reason, :type => Integer #1（回答问卷），2（推广问卷），4（礼品兑换）， 8（管理员操作）,16(处罚操作), 32(邀请样本)，64(撤销订单)
	field :survey_title, :type => String
	field :survey_id, :type => String
	field :gift_name, :type => String
	field :remark, :type => String

	ANSWER = 1
	SPREAD = 2
	REDEEM = 4
	ADMIN_OPERATE = 8
	PUNISH = 16
	INVITE_USER = 32
	REVOKE = 64

	def info_for_sample
		point_log_obj = {}
		point_log_obj["created_at"] = self.created_at.to_i
		point_log_obj["amount"] = self.amount.to_s
		point_log_obj["reason"] = self.reason.to_s
		point_log_obj["survey_title"] = self.survey.title
		point_log_obj["survey_id"] = self.survey._id.to_s
		point_log_obj["gift_name"] = self.gift_name
		point_log_obj["remark"] = self.remark
		return point_log_obj
		
	end
end
