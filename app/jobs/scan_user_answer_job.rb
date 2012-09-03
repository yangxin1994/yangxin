module Jobs

	class ScanUserAnswerJob

		@queue = :sua_job_queue

		def self.perform(*args)

			# 1. find answers which are satisfied that ...
			@answers = find_answers

			# 2. handle answers
			handle_answers
		end

		def self.find_answers

			# answers = Answer.where()
		end

		def self.handle_answers
		end
	end
end