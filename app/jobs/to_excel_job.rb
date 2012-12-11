#encoding: utf-8
module Jobs
  
  class ToExcelJob
    @queue = :to_excel_queue

    def perform
      # #set the type of the job
      p "===== 开始任务 ====="
      set_status({"result_type" => "to_excel"})

      # get parameters

      @survey = Survey.find_by_id(options["survey_id"])
      #pp @survey
      @data_list_result = DataListResult.find(options["data_list_result_id"])
      @result = ExportResult.find_by_result_key(generate_result_key)
      if @result.nil?
        @result = ExportResult.create(:result_key => generate_result_key,
                                      :job_id => status["uuid"])
      else
        ExportResult.create(:result_key => generate_result_key,
                            :job_id => status["uuid"],
                            :ref_job_id => @result.job_id)
        set_status(["ref_job_id"] => @result.job_id)
        return
      end
      p "===== 调用 to_excel ====="
      p to_excel
    end

    def excel_header
      headers =[]
      @survey.all_questions.each_with_index do |e, i|
        headers += e.excel_header("q#{i+1}")
      end
      headers
    end

    def csv_header
      headers = []
      @survey.all_questions.each_with_index do |e, i|
        headers += e.csv_header("q#{i+1}")
      end
      headers
    end
    def to_excel
      send_data '/to_excel' do
        p "===== 准备转换 ====="
        {'excel_data' => {"excel_header" => excel_header,
                         "answer_contents" => answer_contents,
                         "header_name" => csv_header,
                         "result_key" => @result.result_key}.to_yaml}
      end
    end

    def generate_result_key
      answer_ids = @data_list_result.answer_info.map { |e| e._id.to_s }
      result_key = Digest::MD5.hexdigest("to_excel_result-#{answer_ids.to_s}")
      return result_key
    end

  end
end
