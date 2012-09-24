module Jobs

	# Example:
	#
	# Jobs.start(:QuotaJob, 2.hours)
	# , or 
	# Jobs.start(:QuotaJob, 7200)
	def self.start(job_name, time, opt={})
		# check existance of this job
		return false if !Jobs.const_defined?(job_name)
		# return false if interval_time.to_i <= 10

		job_class = Jobs.const_get(job_name)
		recurring = job_class.class_variable_get(:@@recurring)

		# stop the current schedule of the job if it is a recurring job
		stop(job_name) if recurring
		
		# set the new interval time if this is a recurring job
		Resque.redis.set "#{job_name}_last_interval_time", interval_time.to_i if recurring
		# push the job to the job queue
		Resque.enqueue_at(time, 
			Jobs.const_get(job_name), 
			opt)
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