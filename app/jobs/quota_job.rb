
module Jobs

	class QuotaJob

		# store last time interval_time that use to remove_delayed job
		@@last_interval_time = nil
		@queue = :quota_job_queue

		def self.perform(*args)
			puts "Quota Job perform Test: #{Time.now}"

			# # check_quota
			# # return Quota Array
			# rule_arr = check_quota

			# # sample not reject selected
			# select_sample_array = get_select_sample_array(rule_arr)

			# #send_email
			# send_email(select_sample_array)

			# next 
			arg = {}
			arg = args[0] if args[0].class == Hash
			# unit is second
			interval_time =  arg["interval_time"] || 60
			@@last_interval_time = interval_time
			#save to redis
			Resque.redis.set "quota_last_interval_time", @@last_interval_time if @@last_interval_time

			Resque.enqueue_at(Time.now + interval_time.to_i, 
				QuotaJob, 
				{"interval_time"=> interval_time.to_i})

			puts "End Quota Job perform Test. The interval_time is #{interval_time}"
		end

		private 
		# 
		def self.check_quota
			rule_arr = []

			#find all surveys which are published
			published_surveies = Survey.where(status: 8).collect

			published_surveies.each do |survey|
				quota = survey.quota

				tmp_rule_arr = []
				#get the conditions of type==0 to tmp_rule_arr
				quota["rules"].each_index do |rule_index|
					rule = quota["rules"][rule_index]

					# already answer count:
					answer_number = survey.answer_number[rule_index].to_i

					# compute the rest count
					rest_number = rule["amount"].to_i - answer_number
					rest_number = rest_number > 0 ? rest_number : 0

					conditions = []
					rule["conditions"].each do |condition|
						if condition["condition_type"] == 0 then
							conditions << Condititon.new(condition["name"], condition["value"])
						end
					end

					tmp_rule_arr << Rule.new(survey.id.to_s, 	0, conditions, rest_number, condition["fuzzy"]) if conditions.size > 0
				end

				# combine the rules if their have same condition.
				#
				

				# select diff conditions, reject others.
				tmp_rule_arr = tmp_rule_arr.values_at(*diff_rule_indexs) if diff_rule_indexs.size > 0

				# add tmp_rule_arr to rule_arr which is to be return.
				rule_arr += tmp_rule_arr
			end

			return rule_arr
		end


		def self.get_select_sample_array(rule_arr)
			# 
			select_sample_array = []
			rule_arr.each do |rule|
				rule_amount = 0
				if rule.condition_type == 0 then
					Sample.all.each do |sample|
						sample.to_json.each do |key, value|
							if key.to_s == rule.condition_name then
								if !rule.fuzzy && 
								value.to_s == rule.condition_value then
									select_sample_array << [rule.survey_id, sample]
									rule_amount += 1 
								elsif value.to_s.include?(rule.condition_value) then
									select_sample_array << [rule.survey_id, sample]
									rule_amount += 1
								end

								break
							end
						end

						break if rule_amount >= rule.amount
					end
				end
			end

			return select_sample_array
		end

		def self.send_email(select_sample_array)
			select_sample_array.each do |work|
				Resque.enqueue_at_with_queue(1, Time.now, OopsMailJob,{
					:mailler => "netranking",
					:account_name => account[:netranking]["account_name"],
					:account_secret => account[:netranking]["account_secret"],
					:mail_list => ([] << work[1].email),
					:subject => "Happy to invite you to answer survey.",
					:content => ("Hello, this is a new survey. <br/>"+ 
							"if work it for a less time, you are gone to get a reward.<br/>"+
							"click it to <a href=\"http://www.oopsdata.com\">Survey</a>")
				})
			end
		end

	end
end