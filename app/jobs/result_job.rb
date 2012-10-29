#encoding: utf-8

module Jobs

	class ResultJob
		include Resque::Plugins::Status
		include ConnectDotNet
		@queue = :result_job

		def self.answers(survey_id, filter_index, include_screened_answer)
			survey = Survey.find_by_id(survey_id)
			answers = include_screened_answer ? survey.answers.not_preview.finished_and_screened : survey.answers.not_preview.finished
			if filter_index == -1
				set_status({"find_answers_progress" => 1})
				return answers
			end
			filter_conditions = self.survey.filters[filter_index]["conditions"]
			filtered_answers = []
			answers_length = answers.length
			answers.each_with_index do |a, index|
				filtered_answers << a if a.satisfy_conditions(filter_conditions)
				set_status({"find_answers_progress" => (index + 1) * 1.0 / answers_length})
			end
			return filtered_answers	
		end

    def filtered_answers
      #@survey.answers.not_preview.finished_and_screened
      DataListResult.find_by_result_key(@data_list_result.result_key).answer_info
    end

    def answer_contents
      a = filtered_answers
      @retval = []
      q = @survey.all_questions_type
      p "========= 准备完毕 ========="
      @result.answers_count = a.size
      a.each_with_index do |answer, index|
        line_answer = []
        i = -1
        #begin
          #TODO 异常处理
          answer.answer_content.each do |k, v|
            line_answer += q[i += 1].answer_content(v)
          end
        #end
        set_status({"export_answers_progress" => (index + 1) * 1.0 / @result.answers_count })
        
        p "========= 转出 #{index} 条 进度 #{set_status["export_answers_progress"]} =========" if index%10 == 0
        @retval << line_answer
      end
      @result.answer_contents = @retval
      @result.save
      @retval
    end
	end
end
