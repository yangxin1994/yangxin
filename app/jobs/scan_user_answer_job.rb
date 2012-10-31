module Jobs

	class ScanUserAnswerJob

		@@recurring = true
		@queue = :sua_job_queue

		def self.perform(*args)
			arg = {}
			arg = args[0] if args[0].class == Hash
			# unit is second
			interval_time = arg["interval_time"]

			unless interval_time
				puts "Must provide interval_time"
				return false
			end

			# 1. find answers which are satisfied that ...
			@answers = find_answers.to_a

			# 2. handle answers
			handle_answers

			# 3. next 
			Resque.enqueue_at(Time.now + interval_time.to_i, 
				ScanUserAnswerJob, 
				{interval_time: interval_time.to_i}) 	
		end

		def self.find_answers
			Answer.where(is_scanned: false).not_preview.or(
				{status: 2}, 
				{status: 1, reject_type: 0}, 
				{status: 1, reject_type: 2})
		end

		def self.handle_answers
			@answers.each do |answer|
				if answer.user.nil?
					answer.is_scanned = true
					next
				end
				user_id = answer.user._id.to_s

				answer.answer_content.each do |key, value|
					question = BasicQuestion.find_by_id(key)
					if !question.nil? && question.class == TemplateQuestion && !value.blank?
						TemplateQuestionAnswer.update_or_create(key, user_id, value)	
					end
				end
				answer.is_scanned = true
				answer.save
			end
		end
	end
end
