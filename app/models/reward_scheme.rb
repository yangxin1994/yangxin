# encoding: utf-8
require 'error_enum'

class RewardScheme
	include Mongoid::Document
	include Mongoid::Timestamps
    
    # 1 表示话费，2表示支付宝转账，4表示优币，8表示抽奖 
    RewardType = [1,2,4,8]

	field :name, type: String, default: ""
	field :rewards, type: Array, default: []
	field :need_review, type: Boolean, default: false

	MOBILE = 1
	ALIPAY = 2
	POINT = 4
	LOTTERY = 8
	JIFENBAO = 16

	belongs_to :survey

	def self.find_by_id(reward_scheme_id)
		return RewardScheme.where(:_id => reward_scheme_id).first
	end

	def self.create_reward_scheme(survey, reward_scheme)
		retval = verify_reward_scheme_type(reward_scheme)
		return retval if !(retval.to_s == "true")
		new_reward_scheme = RewardScheme.create(reward_scheme)
		survey.reward_schemes << new_reward_scheme
		return true
	end

	def self.update_reward_scheme(reward_scheme_id, reward_scheme)
		retval = verify_reward_scheme_type(reward_scheme)
		return retval if !(retval.to_s == "true")
		reward = RewardScheme.find_by_id(reward_scheme_id)
		reward.update_attributes(reward_scheme)
		return true
	end

	def self.verify_reward_scheme_type(reward_scheme)
		retval = true
		reward_scheme["rewards"].each do |scheme|
			scheme["type"] = ([1, 2, 4, 8].include?(scheme["type"].to_i) ? scheme["type"] : 4)   ##Verify type

			##Verify prize data
			if scheme["type"].to_i == 8
				retval = ErrorEnum::INVALID_PRIZE_ID if Prize.where("id" => scheme["prizes"][0]["id"]).first.nil?
				scheme["prizes"][0]["deadline"] = scheme["prizes"][0]["deadline"].to_i
			end
		end
		reward_scheme["need_review"] = false if !(reward_scheme["need_review"].to_s == "true")
		return retval
	end
end
