class ExportResult < Result
	include Mongoid::Document
	include Mongoid::Timestamps
	include ConnectDotNet

	field :answer_contents, :type => Array, :default => []
	field :file_uri, :type => String
	
	def self.generate_excel_result_key(last_update_time, answers)
		answer_ids = answers.map { |e| e._id.to_s }
		result_key = Digest::MD5.hexdigest("to_excel_result-#{last_update_time}-#{answer_ids.to_s}")
		return result_key
	end

	def self.generate_spss_result_key(last_update_time, answers)
		answer_ids = answers.map { |e| e._id.to_s }
		result_key = Digest::MD5.hexdigest("to_spss_result-#{last_update_time}-#{answer_ids.to_s}")
		return result_key
	end

	def generate_excel(survey, answers, result_key)
		retval = send_data('/ToExcel.aspx') do 
			{'excel_data' => {"csv_header" => survey.csv_header,
												"answer_contents" => survey.formated_answers(answers, result_key),
												"header_name" => survey.csv_header,
												"result_key" => result_key}.to_json,
				'job_id' => task_id.to_s}
		end
		logger.info "3333333333333333333333333"
		logger.info retval.inspect
		logger.info "4444444444444444444444444"
		logger.info retval.body.inspect
		logger.info "5555555555555555555555555"
		self.file_uri = retval.body
		self.status = 1
		self.save
	end

	def generate_spss(survey, answers, result_key)
		retval = send_data('/ToSpss.aspx') do
			{'spss_data' => {"spss_header" => spss_header,
											 "answer_contents" => formated_answers(answers, result_key),
											 "header_name" => csv_header,
											 "result_key" => result_key}.to_json}
		end
		self.file_uri = retval.body
		self.status = 1
		self.save
	end
end