#encoding: utf-8

# coding: utf-8
module Jobs

  class ToSpssJob < ResultJob
    @queue = :to_spss_queue

    def perform(export_result_id)
      p "dsafasdfasdfadsfasfsdafdsafdsafsdafsadfsdfasds"
      # #set the type of the job
      # set_status({"result_type" => "to_spss"})

      # # get parameters
      # @result = ExportResult.find_by_result_id(export_result_id)
      # return if !@result
      # @survey = @result.survey
      # # ===================== #
      # to_spss
    end

    def filtered_answers
      DataListResult.find_by_result_key(@result.result_key).get_answer_info
    end

    def answer_contents
      a = filtered_answers
      @retval = []
      q = @survey.all_questions_type
      p "========= 准备完毕 ========="
      n = 0
      @result.answers_count = answers.size
      a.each do |a|
        line_answer = []
        i = -1
        #begin
          #TODO 异常处理
          a.answer_content.each do |k, v|
            line_answer += q[i += 1].answer_content(v)
          end
        #end
        set_status({"export_answers_progress" => n * 1.0 / @result.answers_count })
        
        p "========= 转出 #{n} 条 进度 #{set_status["export_answers_progress"]} =========" if n%10 == 0
        @retval << line_answer
      end
      @result.answer_contents = @retval
      @result.save
      @retval
    end

    def to_spss
      send_data '/to_spss' do
        p "===== 准备转换 ====="
        {'spss_data' => {"spss_header" => @survey.spss_header,
                         "answer_contents" => answer_contents,
                         "header_name" => @survey.csv_header,
                         "result_key" => @result.result_key,
                         "answers_count" => @result.answers_count,
                         "granularity" =>5}.to_yaml}
      end
    end

  end
end