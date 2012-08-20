
module Jobs

	class QuotaJob

		# store last time interval_time that use to remove_delayed job
		@@last_interval_time = nil
		@queue = :quota_job_queue

		# resque auto involve method
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

		# check quota info for each survey,
		# it will return a array for Jobs::Rule object.
		def self.check_quota
			rule_arr = []

			#find all surveys which are published
			published_surveies = Survey.where(status: 8).to_a

			published_surveies.each do |survey|
				quota = survey.quota
				tmp_rule_arr = []

				#get the conditions of type==0 to tmp_rule_arr
				quota["rules"].each_index do |rule_index|
					rule = quota["rules"][rule_index]
					rule_amount = rule["amount"].to_i

					conditions = []
					rule["conditions"].each do |condition|
						if condition["condition_type"] == 0 then
							conditions << Condition.new(condition["name"], condition["value"])
						end
					end

					#compute rest number
					quota_stats = survey.quota_stats
					answer_number = quota_stats["answer_number"][rule_index].to_i
					rest_number = rule_amount - answer_number

					# change to 0 if tmp_rule_arr element 's amount < 0.
					# because a rule(Rule object) would has two or more rule(survey.quota.rule )
					rest_number = 0 if rest_number < 0

					is_same_rule = false
					tmp_rule_arr.each_index do |diff_index|

						# if a rule which is in tmp_rule_arr has the same conditions,
						# add the amount in tmp_rule_arr element
						# and donot push the rule to tmp_rule_arr.
						if conditions.to_json == tmp_rule_arr[diff_index].conditions.to_json then
							tmp_rule_arr[diff_index].amount += rest_number
							is_same_rule = true 
							break
						else
							is_same_rule = false
						end
					end

					# if not the rule 's conditions be not contains from tmp_rule_arr,
					# push it .
					if !is_same_rule and conditions.size > 0 and rest_number > 0 then
						tmp_rule_arr << Rule.new(survey.id.to_s, 	0, conditions, rest_number) 
					end
				end

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