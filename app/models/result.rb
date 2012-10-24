require 'error_enum'
require 'array'
require 'tool'
class Result
	include Mongoid::Document
	include Mongoid::Timestamps

	field :result_key, :type => String
	field :finished, :type => Boolean, default: false
	field :ref_result_id, :type => String

	belongs_to :survey

	def self.find_by_result_id(result_id)
		return Result.where(:_id => result_id)[0]
	end

	def self.find_by_result_key(result_key)
		return Result.where(:result_key => result_key, :ref_result_id => nil).first
	end

	def self.find_result_by_job_id(job_id)
		result = Result.where(:jog_id => job_id)[0]
		return ErrorEnum::RESULT_NOT_EXIST if result.nil?
		result = result.ref_result_id.nil? ? result : Result.find_by_result_id(result.ref_result_id)
		return ErrorEnum::RESULT_NOT_EXIST if result.nil?

		# based on the result type, return results
		case result._type
		when "DataListResult"
			return result.answer_info
		when "AnalysisResult"
			return {"region_result" => result.region_result,
					"time_result" => result.time_result,
					"duration_result" => result.duration_result,
					"channel_result" => result.channel_result,
					"answers_result" => result.answers_result}
		end
	end

	def self.job_progress(job_id)
		status = Resque::Plugins::Status::Hash.get(job_id)
		status = Resque::Plugins::Status::Hash.get(status["ref_job_id"]) if !status["ref_job_id"].blank?

		return ErrorEnum::JOB_NOT_EXIST if status.nil?

		return 1 if status["is_finished"]
		# calculate the status
		case status["result_type"]
		when "data_list"
			# the data list job consists of two parts
			# the first part is to find the answers by the filter
			s1 = status["find_answers_progress"].to_f
			# the second part is to get the info of the answers
			s2 = status["answer_info_progress"].to_f
			# calculate the total progress
			s = s1 * 0.5 + s2 * 0.5
		when "analysis"
		end
		# the job has not been finished, the progress cannot be greater than 0.99
		return [s, 0.99].max
	end

	def self.generate_result_key(answers)
		answer_ids = answers.map { |e| e._id.to_s }
		result_key = Digest::MD5.hexdigest("analyze_result-#{answer_ids.to_s}")
		return result_key
	end

end