require 'error_enum'
require 'publish_status'
require 'securerandom'

class PublishStatusHistory
	include Mongoid::Document
	include Mongoid::Timestamps
	field :operator_id, :type => String
	field :before_status, :type => Integer
	field :after_status, :type => Integer
	field :message, :type => String
	
	belongs_to :survey

	after_save :after_save_work

	def self.create_new(operator_id, before_status, after_status, message)
		publish_status_rec = PublishStatusHistory.new(:operator_id => operator_id, :before_status => before_status, :after_status => after_status, :message => message)
		retval = publish_status_rec.save
	end

	def after_save_work
		if (self.before_status == PublishStatus::CLOSED || self.before_status == PublishStatus::PAUSED) && self.after_status == PublishStatus::UNDER_REVIEW
			# the survey is submitted, and the status changes from closed or paused to under review
			# 1. need to send administrator email?
		elsif self.before_status == PublishStatus::UNDER_REVIEW && self.after_status == PublishStatus::PUBLISHED
			# the survey has passed the check
			# 1. should send user email
			UserMailer.publish_email(self).deliver
			# 2. should start to schedule tasks to publish this survey
		elsif self.before_status == PublishStatus::UNDER_REVIEW && self.after_status == PublishStatus::PAUSED
			# the survey is rejected to be published
			# 1. should send user email
			UserMailer.reject_email(self).deliver
		elsif self.before_status != PublishStatus::CLOSED && self.after_status == PublishStatus::CLOSED
			# 1. the survey is closed
			# 2. should stop the publishing tasks of this survey
		elsif self.before_status == PublishStatus::PUBLISHED && self.after_status == PublishStatus::PAUSED
			# the survey is paused
			# 1. should stop the publishing tasks of this survey
		end
		return true
	end
end
