module Jobs
	
	class DelUnregisterUserJob

		@queue = :duu_job_queue

		# Time to live
		TTL = 7.days

		def self.perform(*args)
			arg = {}
			arg = args[0] if args[0].class == Hash
			# unit is second
			interval_time = arg["interval_time"]

			unless interval_time
				puts "Must provide interval_time"
				return false
			end

			# do
			check

			#next
			Resque.enqueue_at(Time.now + interval_time.to_i, 
				DelUnregisterUserJob, 
				{"interval_time"=> interval_time.to_i})
		end

		def self.check
			users = User.unregistered.to_a

			users.each do |user|
				answers = user.answers
				next if answers.empty?
				answers.sort!{|v1,v2| v2.created_at <=> v1.created_at} if answers.count > 1
				select_answer = answers[0]
				if Time.now - select_answer.created_at > TTL then
					# delete user
					user.status = -1
					user.save
				end
			end
		end
	end	
end