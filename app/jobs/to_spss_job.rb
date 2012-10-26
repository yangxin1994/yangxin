#encoding: utf-8
module Jobs
  
  class ToSpssJob < ResultJob
    @queue = :to_spss_queue

    def perform
      # #set the type of the job
      p "===== 开始任务 ====="
      set_status({"result_type" => "to_spss"})

      # get parameters

      @survey = Survey.find_by_id(options["survey_id"])
      #pp @survey
      @data_list_result = DataListResult.find(options["data_list_result_id"])
      @result = ExportResult.find_by_data_list_result(generate_result_key, @survey)
      # ===================== #
      p "===== 调用 to_spss ====="
      to_spss
    end

    def spss_header
      headers =[]
      @survey.all_questions.each_with_index do |e, i|
        headers += e.spss_header("q#{i+1}")
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
    def to_spss
      send_data '/to_spss' do
        p "===== 准备转换 ====="
        {'spss_data' => {"spss_header" => spss_header,
                         "answer_contents" => answer_contents,
                         "header_name" => csv_header,
                         "result_key" => @result.result_key,
                         "answers_count" => @result.answers_count,
                         "granularity" => 5}.to_yaml}
      end
    end

    def generate_result_key
      answer_ids = @data_list_result.answer_info.map { |e| e._id.to_s }
      result_key = Digest::MD5.hexdigest("to_spss_result-#{"spss_header.to_s"}-#{answer_ids.to_s}")
      return result_key
    end

  end
end