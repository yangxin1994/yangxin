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
	end

	def self.update_review_scheme(reward_scheme_id, reward_scheme)
		retval = verify_reward_scheme_type(reward_scheme)
		return retval if !retval == true
		reward = RewardScheme.find_by_id(reward_scheme_id)
		reward.update_attributes(reward_scheme)
	end

	def verify_reward_scheme_type(reward_scheme)
		[1, 2, 4, 8].include?(reward_scheme[:type]) ? reward_scheme[:type] : 4   ##Verify type

		##Verify prize data
		return ErrorEnum::INVALID_PRIZE_ID if Prize.where(:id => reward_scheme[:prize][:id]).first == nil
		reward_scheme[:prize][:deadline] = reward_scheme[:prize][:deadline].to_i
		reward_scheme[:need_review] = false if !reward_scheme[:need_review].is_a?(Boolean)
		return true
	end
end
