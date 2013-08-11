# encoding: utf-8
class PointLog < Log
	field :type, :type => Integer, :default => 8
	field :amount, :type => Integer #花费积分数
	field :reason, :type => Integer #1（回答问卷），2（推广问卷），4（礼品兑换）， 8（管理员操作）,16(处罚操作), 32(邀请样本)，64(撤销订单), 128(原有系统导入)
	field :survey_title, :type => String
	field :survey_id, :type => String
	field :scheme_id, :type => String
	field :gift_name, :type => String
	field :gift_type, :type => Integer
	field :gift_id, :type => String
	field :gift_picture_url, :type => String
	field :remark, :type => String

	ANSWER = 1
	SPREAD = 2
	REDEEM = 4
	ADMIN_OPERATE = 8
	PUNISH = 16
	INVITE_USER = 32
	REVOKE = 64
	IMPORT = 128

	def info_for_sample
		point_log_obj = {}
		point_log_obj["created_at"] = self.created_at.to_i
		point_log_obj["amount"] = self.amount
		point_log_obj["reason"] = self.reason
		point_log_obj["survey_title"] = self.survey_title
		point_log_obj["survey_id"] = self.survey_id
		point_log_obj["gift_name"] = self.gift_name
		point_log_obj["gift_type"] = self.gift_type
		point_log_obj["gift_id"] = self.gift_id
		point_log_obj["gift_picture_url"] = self.gift_picture_url
		point_log_obj["remark"] = self.remark
		return point_log_obj
	end

	def info_for_admin
		point_log_obj = {}
		point_log_obj["created_at"] = self.created_at.to_i
		point_log_obj["amount"] = self.amount
		point_log_obj["reason"] = self.reason
		point_log_obj["survey_title"] = self.survey_title
		point_log_obj["survey_id"] = self.survey_id
		point_log_obj["gift_name"] = self.gift_name
		point_log_obj["gift_type"] = self.gift_type
		point_log_obj["gift_id"] = self.gift_id
		point_log_obj["gift_picture_url"] = self.gift_picture_url
		point_log_obj["remark"] = self.remark
		return point_log_obj
	end

	alias :data :info_for_sample

	def self.create_admin_operate_point_log(amount, remark, sample_id)
		self.create(:amount => amount, :reason => ADMIN_OPERATE, :remark => remark, :user_id => sample_id)
	end

	def self.create_answer_point_log(amount, survey_id, survey_title, sample_id)
		self.create(:amount => amount, :reason => ANSWER, :survey_id => survey_id, :survey_title => survey_title, :user_id => sample_id)
	end

	def self.create_spread_point_log(amount, survey_id, survey_title, sample_id)
		self.create(:amount => amount, :reason => SPREAD, :survey_id => survey_id, :survey_title => survey_title, :user_id => sample_id)
	end

	#创建礼品兑换产生的积分变化记录
	def self.create_redeem_point_log(amount, gift_id, sample_id)
		gift = Gift.find_by_id(gift_id)
		gift_name = gift.try(:title)
		gift_picture_url = gift.photo.present? ? gift.photo.picture_url : Gift::DEFAULT_IMG
		case gift.type
		when Gift::MOBILE_CHARGE
			gift_name = "#{amount/100}元话费"
		when Gift::ALIPAY
			gift_name = "#{amount/100}元支付宝"
		when Gift::JIFENBAO
			gift_name = "#{amount}集分宝"
		when Gift::QQ_COIN
			gift_name = "#{amount/100}元Q币"
		end
		self.create(:amount => -amount,
			:gift_id => gift_id,
			:gift_name => gift_name,
			:gift_type => gift.type,
			:reason => PointLog::REDEEM,
			:gift_picture_url => gift_picture_url,
			:user_id => sample_id)
	end
end
