module MyJob
	@queue = :my_job_queue
	def self.perform()
		# Do anything here, like access models, etc
		puts "Doing my job #{Time.now.to_i.to_s}"
	end
end
