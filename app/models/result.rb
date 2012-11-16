require 'error_enum'
require 'array'
require 'tool'
class Result
	include Mongoid::Document
	include Mongoid::Timestamps

	field :job_id, :type => String
	field :result_key, :type => String
	field :status, :type => Integer, default: 0
	field :ref_result_id, :type => String

	belongs_to :survey

	def self.find_by_result_id(result_id)
		return Result.where(:_id => result_id)[0]
	end

	def self.find_by_job_id(job_id)
		result = Result.where(:job_id => job_id).first
		return nil if result.nil?
		return Result.where(:result_key => result.result_key, :ref_result_id => nil).first
	end

	def self.find_by_result_key(result_key)
		return Result.where(:result_key => result_key, :ref_result_id => nil).first
	end

	def self.find_result_by_job_id(job_id)
		result = Result.where(:job_id => job_id)[0]
		return ErrorEnum::RESULT_NOT_EXIST if result.nil?
		result = result.ref_result_id.nil? ? result : Result.find_by_result_id(result.ref_result_id)
		return ErrorEnum::RESULT_NOT_EXIST if result.nil?

		# based on the result type, return results
		case result._type
		when "DataListResult"
			return {"answer_info" => result.answer_info,
					"result_key" => result.result_key}
		when "AnalysisResult"
			return {"region_result" => result.region_result,
					"time_result" => result.time_result,
					"duration_mean" => result.duration_mean,
					"channel_result" => result.channel_result,
					"answers_result" => result.answers_result}
		when "ExportResult"
			# TODO 返回结果
			return {"file_name" => "FinalReport#{result.job_id}.docx"}
		end
	end

	def self.job_progress(job_id)
		status = Resque::Plugins::Status::Hash.get(job_id)
		if status.nil?
			# the status of the job does not exist, try to find the corresponding result
			result = Result.find_by_job_id(job_id)
			# the result cannot be found
			return ErrorEnum::JOB_NOT_EXIST if result.nil?
			# the found job is finished, return 1
			return 1 if result.status == 1
			# the found job is not finished, try to get its status
			status = Resque::Plugins::Status::Hash.get(result["job_id"])
		else
			# the status is found
			result = Result.find_by_job_id(job_id)
			return 1 if result && result.status == 1
			ref_job_id = status["ref_job_id"]
			if !ref_job_id.blank?
				# try to find the real result/job that did the work
				result = Result.find_by_job_id(ref_job_id)
				return ErrorEnum::JOB_NOT_EXIST if result.nil?
				return 1 if result.status == 1
				# the found job is not finished, try to get its status
				status = Resque::Plugins::Status::Hash.get(result["job_id"])
			end
		end
		return -1 if status.nil?

		# the job has not set the status
		return 0 if status["result_type"].nil?

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
			# the analysis job consists of three parts
			# the first part is to find the answers by the filter
			s1 = status["find_answers_progress"].to_f
			# the third part is to analyze data
			s2 = status["analyze_answer_progress"].to_f
			s = s1 * 0.5 + s2 * 0.5
		when "to_spss"
			s1 = status["export_answers_progress"]
			if s1 < 1
				s = s1 * 0.6
			else
				r = ConnectDotNet::get_data("/get_progress") { job_id }
				s2 = r["status"]
				s = s1 * 0.6 + s2 * 0.4
			end
		when "to_excel"
			s1 = status["export_answers_progress"]
			if s1 < 1
				s = s1 * 0.6
			else
				r = ConnectDotNet::get_data("/get_progress") { job_id }
				s2 = r["status"]
				s = s1 * 0.6 + s2 * 0.4
			end
		when "report"
			s1 = status["find_answers_progress"].to_f
			if s1 < 1
				s = s1 * 0.3
			else
				s2 = status["data_conversion_progress"].to_f
#				if s2 < 2
					s = s1 * 0.3 + s2 * 0.2
#				else
#					s3 = ConnectDotNet::get_data("/get_progress") { job_id }
#					s = s1 * 0.3 + s2 * 0.2 + s3 * 0.5
#				end
			end
		end
		# the job has not been finished, the progress cannot be greater than 0.99
		return [s, 0.99].min
	end

	def self.generate_result_key(answers)
		answer_ids = answers.map { |e| e._id.to_s }
		result_key = Digest::MD5.hexdigest("analyze_result-#{answer_ids.to_s}")
		return result_key
	end

end