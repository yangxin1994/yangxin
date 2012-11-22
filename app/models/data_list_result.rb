require 'error_enum'
require 'array'
require 'tool'
require 'digest/md5'
class DataListResult < Result
	include Mongoid::Document
	include Mongoid::Timestamps

	field :answer_info, :type => Array

	belongs_to :survey

	def get_answer_info
		ref_result_id.nil? ? answer_info : Result.find_by_result_id(result.ref_result_id).answer_info
	end

	def self.generate_result_key(answers)
		answer_ids = answers.map { |e| e._id.to_s }
		result_key = Digest::MD5.hexdigest("data_list-#{answer_ids.to_s}")
		return result_key
	end

	def analyze_answer_info(answers, task_id=nil)
		answer_info = []
		answers_length = answers.length
		answers.each_with_index do |a, index|
			info = {}
			info["email"] = a.user.nil? ? "" : a.user.email.to_s
			info["full_name"] = a.user.nil? ? "" : a.user.full_name.to_s
			info["answer_time"] = a.created_at.to_i
			info["duration"] = a.finished_at - a.created_at.to_i
			info["region"] = a.region
			answer_info << info
			TaskClient.set_progress(task_id, "answer_info_progress", (index + 1).to_f / answers_length) if !task_id.nil?
		end
		self.answer_info = answer_info
		self.status = 1
		return self.save
	end
end
