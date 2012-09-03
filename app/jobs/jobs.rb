module Jobs

	# Example:
	#
	# Jobs.start(:QuotaJob, 2.hours)
	# , or 
	# Jobs.start(:QuotaJob, 7200)
	def self.start(job_name, interval_time)
		return false if !Jobs.const_defined?(job_name)
		return false if interval_time.to_i <= 10

		stop(job_name)
		
		#save to redis
		Resque.redis.set "#{job_name}_last_interval_time", interval_time.to_i
		Resque.enqueue_at(Time.now, 
			Jobs.const_get(job_name), 
			{"interval_time"=> interval_time.to_i})
	end

	def self.stop(job_name)
		#remove relative data from redis
		if Jobs.const_get(job_name).instance_variable_defined?(:@queue)
			Resque.redis.srem("queues", Jobs.const_get(job_name).instance_variable_get(:@queue)) 
		end
	
		# remove delayed job from scheduler method
		# because remove_delayed method need params, 
		# so it set a quota_last_interval_time variable to redis 
		# then get it in here.
		interval_time = Resque.redis.get "#{job_name}_last_interval_time"
		retval = Resque.remove_delayed(Jobs.const_get(job_name), "interval_time" => interval_time.to_i) if interval_time
		
		retval = retval.nil? || retval >= 1 ? true : false
	end

end