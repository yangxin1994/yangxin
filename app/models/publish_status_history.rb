require 'error_enum'
require 'quill_common'
require 'securerandom'

class PublishStatusHistory
	include Mongoid::Document
	include Mongoid::Timestamps
	field :operator_id, :type => String
	field :before_status, :type => Integer
	field :after_status, :type => Integer
	field :message, :type => String

	belongs_to :survey

	# after_save :after_save_work

	def self.start_publish_time
		PublishStatusHistory.where(after_status: QuillCommon::PublishStatusEnum::PUBLISHED).(sort: [[ :created_at, :desc ]]).map { |e| e.created_at.to_i }
	end

	def self.end_publish_time
		PublishStatusHistory.where(before_status: QuillCommon::PublishStatusEnum::PUBLISHED).(sort: [[ :created_at, :desc ]]).map { |e| e.created_at.to_i }
	end

	def self.create_new(operator_id, before_status, after_status, message)
		publish_status_rec = PublishStatusHistory.new(:operator_id => operator_id, :before_status => before_status, :after_status => after_status, :message => message)
		publish_status_rec.save
		return publish_status_rec
	end
end
