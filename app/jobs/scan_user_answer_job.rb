module Jobs

	class ScanUserAnswerJob

		@queue = :sua_job_queue

		def self.perform(*args)

			# 1. find answers which are satisfied that ...
			@answers = find_answers.to_a

			# 2. handle answers
			handle_answers
		end

		def self.find_answers
			Answer.or({is_scanned: false, status: 2}, 
				{is_scanned: false, status: 1, reject_type: 0}, 
				{is_scanned: false, status: 1, reject_type: 2})
		end

		def self.handle_answers
			@answers.each do |answer|
				next if answer.user.nil?
				user_id = answer.user._id.to_s

				template_answer_content = answer.template_answer_content

				template_answer_content.each do |key, value|
					question = Question.find(key.to_s)
					template_question_id = question.reference_id if question

					if template_question_id && user_id && !value.blank? then
						TemplateQuestionAnswer.update_or_create(template_question_id, 
							user_id, value)	
					end
				end

				answer.is_scanned = true
				answer.save
			end
		end
	end
end