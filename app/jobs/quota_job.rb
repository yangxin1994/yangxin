# coding: utf-8

module Jobs

	class QuotaJob

		# store last time interval_time that use to remove_delayed job
		@queue = :quota_job_queue

		def self.start(interval_time)
			stop
			if interval_time.to_i > 10 then
				#save to redis
				Resque.redis.set "quota_last_interval_time", interval_time.to_i
				Resque.enqueue_at(Time.now, 
					QuotaJob, 
					{"interval_time"=> interval_time.to_i})
			else
				false
			end
		end

		def self.stop
			#remove relative data from redis
			Resque.redis.srem("queues", QuotaJob.instance_variable_get(:@queue)) if QuotaJob.instance_variable_defined?(:@queue)
		
			# remove delayed job from scheduler method
			# because remove_delayed method need params, 
			# so it set a quota_last_interval_time variable to redis 
			# then get it in here.
			interval_time = Resque.redis.get "quota_last_interval_time"
			retval = Resque.remove_delayed(QuotaJob, "interval_time" => interval_time.to_i) if interval_time
			
			retval = retval.nil? || retval == 1 ? true : false
		end

		# resque auto involve method
		def self.perform(*args)
			puts "Quota Job perform Test: #{Time.now}"
			# 1. get all samples, excluding those are in the blacklist
			@user_ids = User.ids_not_in_blacklist
			# 2. summarize the quota rules of the surveys
			@rule_arr = check_quota
			# 3. find out samples for surveys
			@samples_found = find_samples
			# 4. send emails to the samples found
			send_emails
			# 5. prepare for the next execuation
			arg = {}
			arg = args[0] if args[0].class == Hash
			# unit is second
			interval_time = arg["interval_time"]
			puts "End Quota Job perform Test. The interval_time is #{interval_time}"
			Resque.enqueue_at(Time.now + interval_time.to_i, 
				QuotaJob, 
				{"interval_time"=> interval_time.to_i}) 		
		end

		def self.send_emails
			# 1. calculate the survey invitations for each sample
			ready_to_send = {}
			@samples_found.each_with_index do |samples_found_for_one_survey, index|
				survey_id = @rule_arr[index].survey_id
				samples_found_for_one_survey.each do |sample|
					ready_to_send[sample] ||= []
					ready_to_send[sample] << survey_id if !ready_to_send[sample].include?(survey_id)
				end
			end
			# 2. send out emails and save results
			surveys = {}
			@rule_arr.each do |rule|
				surveys[rule.survey_id] = Survey.find_by_id(rule.survey_id)
			end
			ready_to_send.each do |user_id, survey_id_list|
				user = User.find_by_id(user_id)
				survey_id_list.each do |survey_id|
					email_history = EmailHistory.create
					email_history.user = user
					email_history.survey = surveys[survey_id]
				end
			end
		end

		def self.find_samples
			samples_found = []
			user_ids_answered = {}
			user_ids_sent = {}
			@rule_arr.each do |rule|
				s_id = rule["survey_id"]
				user_ids_answered[s_id] ||= Answer.get_user_ids_answered(s_id)
				user_ids_sent[s_id] ||= EmailHistory.get_user_ids_sent(s_id)
				users_id = @users_id - user_ids_answered[s_id] - user_ids_sent[s_id]
				user_ids_satisfied = nil
				rule["conditions"].each do |c|
					if user_ids_satisfied.nil?
						user_ids_satisfied = TemplateQuestionAnswer.user_ids_satisfied(users_id, c)
					else
						user_ids_satisfied &= TemplateQuestionAnswer.user_ids_satisfied(users_id, c)
					end
				end
				if user_ids_satisfied.length >= rule.email_number
					samples_found << user_ids_satisfied.shuffle[0..rule.email_number-1]
					next
				end
				user_ids_unsatisfied = []
				rule["conditions"].each do |c|
					user_ids_unsatisfied |= TemplateQuestionAnswer.user_ids_unsatisfied(users_id, c)
				end
				user_ids_unknow = users_id - user_ids_satisfied - user_ids_unsatisfied
				user_ids_selected = user_ids_satisfied 
							+ user_ids_unknow.shuffle[0..rule.email_number-user_ids_satisfied.length-1]
				samples_found << user_ids_selected
			end
			return samples_found
		end

		# check quota info for each survey,
		# it will return a array for Jobs::Rule object.
		def self.check_quota
			rule_arr = []
			#find all surveys which are published
			published_survey = Survey.get_published_active_surveys
			# puts "published_survey count:: #{published_survey}"
			published_survey.each do |survey|
				cur_survey_rule_arr = []
				survey.quota["rules"].each_with_index do |rule, rule_index|
					rule_amount = rule["amount"].to_i

					# 1. get the conditions
					conditions = []
					rule["conditions"].each do |condition|
						if condition["condition_type"] == 0 then
							conditions << Condition.new(condition["name"], condition["value"])
						end
					end

					# 2. get the remainning number
					answer_number = survey.quota_stats["answer_number"][rule_index].to_i
					rest_number = rule_amount < answer_number ? 0 : rule_amount - answer_number

					# 3. combine the rule
					has_same = false
					cur_survey_rule_arr.each do |rule|
						if compare_conditions(conditions, rule.conditions)
							rule.amount_increase(rest_number)
							has_same = true
							break
						end 
					end

					if has_same == false && rest_number > 0 then
						cur_survey_rule_arr << 	Rule.new(survey._id.to_s, conditions, rest_number) 
					end
				end
				rule_arr += cur_survey_rule_arr
			end
			return rule_arr
		end

		def self.compare_conditions(c1, c2)
			return JSON.parse(c1.to_json) - JSON.parse(c2.to_json) == [] && 
			JSON.parse(c2.to_json) - JSON.parse(c1.to_json) == []
		end

		def self.send_email(sample)
			list_surveys_str = ""
			sample.meet_surveys.each do |survey_id|
				list_surveys_str += "<a href=\"http://www.oopsdata.com/surveys/#{survey_id}\">#{survey_id}</a>\n"
			end

			content = "Hi! #{sample.user_id}. OopsData is very happy to invite you to answer survey.
	If work it for a less time, you are gone to get a reward probablely.
	Now, we choose some for you which fit you.

	#{list_surveys_str}
	More, click <a href=\"http://www.oopsdata.com\">OopsData</a>"

			# binding.pry
				
			# Resque.enqueue_at_with_queue(1, Time.now, OopsMailJob,{
			# 	:mailler => "netranking",
			# 	:account_name => account[:netranking]["account_name"],
			# 	:account_secret => account[:netranking]["account_secret"],
			# 	:mail_list => ([] << sample.email),
			# 	:subject => "Happy to invite you to answer survey.",
			# 	:content => content
			# })

				puts "send_email content::: #{content}"

				sample.last_email_time = Time.now
			end
		end
end
