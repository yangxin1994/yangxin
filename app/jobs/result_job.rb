module Jobs

	class ResultJob
		include Resque::Plugins::Status

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

	end
end
