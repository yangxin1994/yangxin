# encoding: utf-8
require 'error_enum'

class RewardScheme
	include Mongoid::Document
	include Mongoid::Timestamps
    
	field :name, type: String, default: ""
	field :rewards, type: Array, default: []
	field :need_review, type: Boolean, default: false
	field :default, type: Boolean, default: false

	MOBILE = 1
	ALIPAY = 2
	POINT = 4
	LOTTERY = 8
	JIFENBAO = 16
	
	CASH_REWARD = "1,2,16"
	FREE = "0"

	belongs_to :survey
	has_many :answers
	has_many :agent_tasks

	scope :not_default, where(default: false)

	index({ default: 1 }, { background: true } )

	def self.find_by_id(reward_scheme_id)
		return RewardScheme.where(:_id => reward_scheme_id).first
	end

	def self.create_reward_scheme(survey, reward_scheme)
		retval = verify_reward_scheme_type(reward_scheme)
		return retval if !(retval.to_s == "true")
		new_reward_scheme = RewardScheme.create(reward_scheme)
		survey.reward_schemes << new_reward_scheme
		return new_reward_scheme
	end

	def self.update_reward_scheme(reward_scheme_id, reward_scheme)
		retval = verify_reward_scheme_type(reward_scheme)
		return retval if !(retval.to_s == "true")
		reward = RewardScheme.not_default.find_by_id(reward_scheme_id)
		reward.update_attributes(reward_scheme)
		return true
	end

	def self.verify_reward_scheme_type(reward_scheme)
		retval = true
		reward_scheme["rewards"].each do |reward|
			reward["type"] = ([1, 2, 4, 8, 16].include?(reward["type"].to_i) ? reward["type"] : 4)   ##Verify type
		end
		reward_scheme["need_review"] = false if !(reward_scheme["need_review"].to_s == "true")
		return retval
	end
end
