# encoding: utf-8
require 'error_enum'

class RewardScheme
	include Mongoid::Document
	include Mongoid::Timestamps

	field :rewards, type: Array, default: []
	field :need_review, type: Boolean, default: false

	belongs_to :survey

	def self.find_by_id(reward_scheme_id)
		return RewardScheme.where(:_id => reward_scheme_id).first
	end

	def self.create_reward_scheme(survey_id, reward_scheme)
		retval = verify_reward_scheme_type(reward_scheme)
		return retval if !retval == true
		RewardScheme.create(reward_scheme)
		return true
	end

	def self.update_review_scheme(reward_scheme_id, reward_scheme)
		retval = verify_reward_scheme_type(reward_scheme)
		return retval if !retval == true
		reward = RewardScheme.find_by_id(reward_scheme_id)
		reward.update_attributes(reward_scheme)
		return true
	end

	def self.verify_reward_scheme_type(reward_scheme)
		retval = true
		reward_scheme["rewards"].each do |scheme|
			scheme["type"] = ([1, 2, 4, 8].include?(scheme["type"].to_i) ? scheme["type"] : 4)   ##Verify type

			##Verify prize data
			if scheme["type"] == 8
				retval = ErrorEnum::INVALID_PRIZE_ID if Prize.where("id" => scheme["prize"]["id"]).first == nil
				reward_scheme["prize"]["deadline"] = reward_scheme["prize"]["deadline"].to_i
			end
		end
		reward_scheme["need_review"] = false if reward_scheme["need_review"].nil?
		return retval
	end
end
