# coding: utf-8

module Jobs

	class QuotaJob

		# store last time interval_time that use to remove_delayed job
		@queue = :quota_job_queue

		MaxCountOfReceivingSurveies = 2
		MaxCountOfDescingConditionForWhile = 1
		
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

			# # check_quota
			# # return Quota Array
			# rule_arr = check_quota

			# # sample not reject selected
			# select_sample_array = get_select_sample_array(rule_arr)

			# #send_email
			# send_email(select_sample_array)

			# rule_arr = check_quota

			# get_select_answer_templates(rule_arr)


			# next 
			arg = {}
			arg = args[0] if args[0].class == Hash
			# unit is second
			interval_time = arg["interval_time"]

			puts "End Quota Job perform Test. The interval_time is #{interval_time}"
			Resque.enqueue_at(Time.now + interval_time.to_i, 
				QuotaJob, 
				{"interval_time"=> interval_time.to_i}) 		
		end

		# check quota info for each survey,
		# it will return a array for Jobs::Rule object.
		def self.check_quota
			rule_arr = []

			#find all surveys which are published
			published_surveies = Survey.where(status: 8).to_a

			published_surveies.each do |survey|
				tmp_rule_arr = []
				#get the conditions of type==0 to tmp_rule_arr
				survey.quota["rules"].each_with_index do |rule, rule_index|
					rule_amount = rule["amount"].to_i

					conditions = []
					rule["conditions"].each do |condition|
						if condition["condition_type"] == 0 then
							conditions << Condition.new(condition["name"], condition["value"])
						end
					end

					#compute rest number
					answer_number = survey.quota_stats["answer_number"][rule_index].to_i
					rest_number = rule_amount < answer_number ? 0 : rule_amount - answer_number

					tmp_rule_arr.each_with_index do |rule, diff_index|
						# if a rule which is in tmp_rule_arr has the same conditions,
						# add the amount in tmp_rule_arr element
						# and donot push the rule to tmp_rule_arr.
						if conditions - rule.conditions == [] && rule.conditions - conditions == []
							rule.amount_increase(rest_number)
							break
						else
							tmp_rule_arr << Rule.new(survey.id.to_s, 0, conditions, rest_number) if conditions.size > 0 && rest_number > 0
						end
					end
				end

				rule_arr += tmp_rule_arr
			end
			return rule_arr
		end

		class TemplateQuestionAnswer
			attr_accessor :meet_surveys
		end

		# Find some templates who do not send email recently.
		def self.templates_before_filter(templates)
			# templates.sort!{|v1,v2| v1.last_email_time <=> v2.last_email_time} if templates.count > 1
			templates
		end

		# it must return false or true
		def self.compare_template_rule(template, rule)
			return 	rule.email_number > 0 &&
					!rule.sample_ids.include?(template.user_id) &&
					JSON.parse(template.conditions.to_json) & 
					JSON.parse(rule.conditions.to_json) == 
					JSON.parse(rule.conditions.to_json) &&
					rule.pop_conditions_names &
					template.conditions_names == []
		end

		# this method start of answer_templates.each
		#
		def self.get_select_answer_templates(rule_arr)

			#
			# First, we should compare tempates with rule_arr
			#

			#
			# 1: Find some templates who do not send email recently.
			# Method: templates_before_filter
			#

			# answer_templates = templates_filter(TemplateQuestionAnswer.all.to_a)
			answer_templates = templates_before_filter(Sample.all) # for test
			return [] if answer_templates.count == 0

			select_answer_templates = select_block(answer_templates, rule_arr)

			# Other work.
			# if it is end of all templates, but rule_arr.count > 0 .
			# That is, rule arr not satisfied with all templates.
			# So, we should bring down conditions of rule_arr.each_rule.
			#while_count = 0
			#while while_count < MaxCountOfDescingConditionForWhile && rule_arr.count > 0 do
			while true
				# bring down conditions
				puts "**********bring down conditions  rules**********"
				all_nil = true
				rule_arr.each do |rule|
					rule.conditions.each do |condition|
						if !condition.value.nil?
							condition.value = nil
							all_nil = false
							break
						end
					end
					# pop_condition = rule.conditions.pop if rule.conditions.count > 0
					# rule.pop_conditions_names << pop_condition.name if pop_condition
					puts "bring down:rule:: #{rule.to_s}"
				end
				# if all the conditions are nil, it means that we can not satisfy the "amount"
				break if all_nil

				# sort answer_templates again
				# and consider of select_answer_templates.
				#
				# The select_answer_templates should be top.
				# Next,
				# other answer_templates should be order with last_email_time.
				# What's more, 
				# templates which have sent in this time should not be in it.
				answer_templates.select!{|template| !select_answer_templates.include?(template)}
				templates_before_filter(select_answer_templates)
				answer_templates = select_answer_templates + answer_templates

				puts "**********combine's answer_templates**********"
				answer_templates.each do |element|
					puts "combine template::: #{element.to_s}"
				end

				select_answer_templates = []
				select_answer_templates = select_block(answer_templates, rule_arr)
			end

			# # End,
			# # although some rules not be satisfied, but template is over.
			# # Then, we send email for select_answer_templates 
			# # which 's survey_ids < MaxCountOfReceivingSurveies
			# send_emails(select_answer_templates)
		end

		def self.select_block(templates, rules)
			select_templates = []
			templates.each_index do |index|

				# template[index] maybe a nil due to templates which will be changed
				break if templates[index].nil?
				puts "%%%%%%%%%%%%%%%%%template::#{templates[index].to_s}"

				break if rules.count == 0

				# sort desc of email_number
				rules.sort!{|v1, v2| v2.email_number <=> v1.email_number} if rules.count > 1
				puts "sort &&&&&&&&&&&&&&&&&&&&&&&&&&&&"
				rules.each {|rule| puts "after rule ::: #{rule.to_s}"}	

				# init template_send_email variable
				# if current template sends email at follows step,
				# it should be true.
				template_send_email = false

				#
				# 2: Find some rules who fit with this template.
				rules.each do |rule|

					templates[index].meet_surveys ||= []

					#
					# 2.1: compare conditions
					#

					# binding.pry

					if compare_template_rule(templates[index], rule) then

						# puts ">>>>>>>>>"

						# next if rule.sample_ids.include?(templates[index].user_id)
						rule.sample_ids << templates[index].user_id

						# add tmp field: meet_surveys in template_question_answer object 
						# that store survey ids
						templates[index].meet_surveys ||= []
						if !templates[index].meet_surveys.include?(rule.survey_id) then
							templates[index].meet_surveys << rule.survey_id
						end

						# a template_question_answer object which include one rule 
						# should be in select_answer_templates 
						if !select_templates.include?(templates[index]) then
							select_templates << templates[index]
						end
						rules.reject!{|a| a == rule}  if rule.email_number_decrease <= 0

						# find other rules with same of the current rule 's survey_id/
						# because this can use this templates[index] max-ily when
						#
						# if templates[index].meet_surveys.size >= MaxCountOfReceivingSurveies then 
						# 	# send email ??? 
						# 	send_email(templates[index])
						# 	break  
						# end
						#
						# this code send email.
						same_survey_rules = rules.select{|element| element != rule && element.survey_id == rule.survey_id}
						same_survey_rules.each do |rule2|
							if compare_template_rule(templates[index], rule2) then
								rules.reject!{|a| a == rule2}  if rule2.email_number_decrease <= 0
								rule2.sample_ids << templates[index].user_id
							end
						end
					end

					if templates[index].meet_surveys.size >= MaxCountOfReceivingSurveies then
						# send email ???
						send_email(templates[index])
						# remove tempate which sends email from select_answer_tmplates
						select_templates.reject!{|element| element == templates[index]}
						# because this template has sent email, and it should be removed from templates
						# which assures that not send email in secondly.
						templates.reject!{|element| element == templates[index]}
						#change template_send_email
						template_send_email = true
						break 
					end
				end

				puts "deal rules $$$$$$$$$$$$$$$$$$"
				rules.each {|rule| puts "after rule ::: #{rule.to_s}"}

				# if template_send_email is true, the templates' count would be changed.
				# so, we should redo more one time.
				# Example:
				# arr = [1,2,3]
				# arr.each{|e| puts e.to_s; arr.reject!{|el| el==2 && e==2}}
				# it will output: 1 2, arr = [1,3]. but not print 3.
				# However, now we need to remove 2(arr=[1,3]) and output 1 2 3. So, we can:
				# arr.each_index{|index| puts arr[index].to_s; if arr[index]==2 then arr.reject!{|el| el==2}; redo; end;}
				redo if template_send_email
			end

			return select_templates
		end

		def self.send_emails(select_sample_array)
			select_sample_array.each do |work|
				send_email(work)
			end
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
