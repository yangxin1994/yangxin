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
		excel_data_json = {"csv_header" => survey.csv_header,
												"answer_contents" => survey.formated_answers(answers, result_key),
												"header_name" => survey.csv_header,
												"result_key" => result_key}.to_json
		retval = send_data('/ToExcel.aspx') do 
			{'excel_data' => excel_data_json, 'job_id' => task_id.to_s}
		end
		return retval if retval.to_s.start_with?('error')
		return ErrorEnum::DOTNET_HTTP_ERROR if retval.code != "200"
		return ErrorEnum::DOTNET_INTERNAL_ERROR if retval.body.start_with?('error:')
		self.file_uri = retval.body
		self.status = 1
		return self.save
	end

	def generate_spss(survey, answers, result_key)
		spss_data_json = {"spss_header" => survey.spss_header,
											 "answer_contents" => survey.formated_answers(answers, result_key),
											 "header_name" => survey.csv_header,
											 "result_key" => result_key}.to_json
		retval = send_data('/ToSpss.aspx') do
			{'spss_data' => spss_data_json, 'job_id' => task_id.to_s}
		end
		return retval if retval.to_s.start_with?('error')
		return ErrorEnum::DOTNET_HTTP_ERROR if retval.code != "200"
		return ErrorEnum::DOTNET_INTERNAL_ERROR if retval.body.start_with?('error:')
		self.file_uri = retval.body
		self.status = 1
		return self.save
	end
end