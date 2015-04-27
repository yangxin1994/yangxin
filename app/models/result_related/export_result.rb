# encoding: utf-8
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
#    if answers.count > 1500
#      uris = []
#			page_count = answers.count / 500
#      page_count.times do |_count|
#        a_count = _count * (answers.count / page_count)
#        _a = answers.slice(a_count, answers.count / page_count)
#          # _a = answers.slice(100, 15)
#        excel_data_json = {
#          "excel_header" => survey.excel_header,
#          "answer_contents" => survey.formated_answers(_a, result_key, task_id.to_s),
#          "header_name" => survey.csv_header,
#          "result_key" => result_key
#        }.to_json      
#        retval = ConnectDotNet.send_data('/ToExcel.aspx') do
#          {'excel_data' => excel_data_json.gsub(/<[^>]*>/, ''), 'job_id' => "#{task_id}_#{_count}"}
#        end
#        uris << retval.body
#      end
#      file_name = "public/import/#{task_id}.txt"
#      File.open(file_name, "wb") { |file| file.puts(uris.join("\n"))}
#      File.open("public/uploads/excel.html", "wb") { |file| file.puts(uris.join("\n"))}
#			self.status = 1
#      self.file_uri = file_name
#      return save
#    else
      excel_data_json = {
      "excel_header" => survey.excel_header,
      "answer_contents" => survey.formated_answers(answers, result_key, task_id.to_s),
      "header_name" => survey.csv_header,
      "result_key" => result_key
      }.to_json
      
    
      retval = ConnectDotNet.send_data('/ToExcel.aspx') do
        {'excel_data' => excel_data_json.gsub(/<[^>]*>/, ''), 'job_id' => task_id.to_s}
      end

		  if retval.to_s.start_with?('error')
        self.status = -1
        self.error_code = retval
      elsif retval.code != "200"
        self.status = -1
        self.error_code = ErrorEnum::DOTNET_INTERNAL_ERROR
      elsif retval.body.start_with?('error:')
        return ErrorEnum::DOTNET_INTERNAL_ERROR
        self.status = -1
        self.error_code = ErrorEnum::DOTNET_INTERNAL_ERROR
	    else
        File.open("public/uploads/excel.html", "wb") { |file| file.puts(retval.body.to_s)}
		    self.status = 1
        self.file_uri = retval.body
      end
      self.save
#		end
  end

  def generate_spss(survey, answers, result_key)
    # #========================
    #   uris = []
    #   20.times do |_count|
    #     a_count = _count * (answers.count / 20)
    #     _a = answers.slice(a_count, answers.count / 20)
    #     excel_data_json = {
    #     "excel_header" => survey.spss_header,
    #     "answer_contents" => survey.formated_answers(_a, result_key, task_id.to_s),
    #     "header_name" => survey.csv_header,
    #     "result_key" => result_key
    #     }      
    #     retval = ConnectDotNet.send_data('/ToSpss.aspx') do
    #       {'spss_data' => excel_data_json.to_json, 'job_id' => "#{task_id}_#{_count}"}
    #     end
    #     uris << retval.body
    #   end
    #   file_name = "public/import/#{task_id}.txt"
    #   File.open(file_name, "wb") { |file| file.puts(uris.join("\n"))}
    #   self.status = 1
    #   self.file_uri = file_name
    #   return save



    # #========================
    puts "aa"
    spss_data_json = {"spss_header" => survey.spss_header,
                      "answer_contents" => survey.formated_answers(answers, result_key, task_id.to_s),
                      "header_name" => survey.csv_header,
                      "result_key" => result_key}.to_json

    puts "answer_contents_length:#{spss_data_json["answer_contents"].length}"

    puts spss_data_json.inspect
    puts spss_data_json.gsub(/<[^>]*>/, '')
    retval = ConnectDotNet.send_data('/ToSpss.aspx') do
      {'spss_data' => spss_data_json.gsub(/<[^>]*>/, ''), 'job_id' => task_id.to_s}
    end
    puts 'a'
    File.open("public/uploads/spss.html", "wb") { |file| file.puts(retval.body.to_s)}
    puts 'b'
    if retval.to_s.start_with?('error')
      self.status = -1
      self.error_code = retval
    elsif retval.code != "200"
      self.status = -1
      self.error_code = ErrorEnum::DOTNET_HTTP_ERROR
    elsif retval.body.start_with?('error:')
      return ErrorEnum::DOTNET_INTERNAL_ERROR
      self.status = -1
      self.error_code = ErrorEnum::DOTNET_INTERNAL_ERROR
    else
      self.status = 1
      self.file_uri = retval.body
    end
    self.save
  end
end
