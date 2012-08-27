# coding: utf-8
require 'test_helper'

class QuotaJobTest < ActiveSupport::TestCase

	test "01 should get rule arr from check_quota" do 
		clear(Survey)

		assert Jobs::QuotaJob.methods.include?(:check_quota)
		assert_equal Survey.all.count, 0
		survey = FactoryGirl.create(:survey_with_quota_1)
		assert_equal Survey.where(status: 8).count, 1
		conditions = []
		conditions << Jobs::Condition.new("tp_q_1", "male")
		conditions << Jobs::Condition.new("tp_q_2", "23")
		rule1 = Jobs::Rule.new(Survey.first.id, 0, conditions, 200)
		conditions = []
		conditions << Jobs::Condition.new("tp_q_1", "male")
		rule2 = Jobs::Rule.new(Survey.last.id, 0, conditions, 50)

		# puts "check_quota ............"
		assert_equal Jobs::QuotaJob.check_quota.to_json, ([] << rule1 << rule2).to_json

		clear(Survey)
	end

	test "02 should get_select_answer_templates"  do
		clear(Survey)

		assert Jobs::QuotaJob.methods.include?(:check_quota)
		assert_equal Survey.all.count, 0
		FactoryGirl.create(:survey_with_quota_1)
		FactoryGirl.create(:survey_with_quota_2)
		assert_equal Survey.where(status: 8).count, 2

		rule_arr = Jobs::QuotaJob.check_quota
		puts "***********before rule***********"
		rule_arr.each {|rule| puts "before rule ::: #{rule.to_s}"}
		puts "*************get_select_answer_templates2*********"
		select_answer_templates = Jobs::QuotaJob.get_select_answer_templates(rule_arr)
		puts "*********after rules*************"
		rule_arr.each {|rule| puts "after rule ::: #{rule.to_s}"}
		puts "***********select_answer_templates***********"
		select_answer_templates.each {|template| puts "template ::: #{template.to_s}"}
		# puts "**********Sample.all.*******************"
		# Jobs::Sample.all.each{|template| puts "template ::: #{template.to_s}"}
		# assert_equal JSON.parse(select_answer_templates.to_json), JSON.parse(([]).to_json)

		# Jobs::QuotaJob.send_emails(select_answer_templates)
	end

	# test "03 should get_select_answer_templates2"  do
	# 	clear(Survey)

	# 		assert Jobs::QuotaJob.methods.include?(:check_quota)
	# 		assert_equal Survey.all.count, 0
	# 		quota_hash = {	"rules" => 	[
	# 							{   "conditions" => [
	# 									{"condition_type" => 0, 
	# 									"name" => "tp_q_1", 
	# 									"value" => "male"
	# 									},
	# 									{"condition_type" => 0, 
	# 									"name" => "tp_q_2", 
	# 									"value" => "23"
	# 									},
	# 									{"condition_type" => 1,
	# 									"name" => "tp_q_3", 
	# 									"value" => "apple"
	# 									}
	# 												],
	# 								"amount" => 5
	# 							},
	# 							{   "conditions" => [
	# 									{"condition_type" => 0, 
	# 									"name" => "tp_q_1", 
	# 									"value" => "male"
	# 									},
	# 									{"condition_type" => 0, 
	# 									"name" => "tp_q_2", 
	# 									"value" => "23"
	# 									},
	# 									{"condition_type" => 1,
	# 									"name" => "tp_q_3", 
	# 									"value" => "pear"
	# 									}
	# 												],
	# 								"amount" => 4
	# 							},
	# 							{   "conditions" => [
	# 									{"condition_type" => 0, 
	# 									"name" => "tp_q_1", 
	# 									"value" => "male"
	# 									},
	# 									{"condition_type" => 1,
	# 									"name" => "tp_q_3", 
	# 									"value" => "pear"
	# 									}
	# 												],
	# 								"amount" => 3
	# 							}
	# 									]
	# 						}

	# 	quota_stats = {"answer_number" => [1,2,2]}
	# 	survey = Survey.create({"quota" => quota_hash, "status" => 8, "quota_stats" => quota_stats})
	# 	assert_equal Survey.all.count, 1
	# 	survey = Survey.first
	# 	assert_not_equal survey, nil
	# 	assert_equal survey.quota, quota_hash
	# 	assert_equal Survey.where(status: 8).count, 1

	# 	rule_arr = Jobs::QuotaJob.check_quota
	# 	select_answer_templates = Jobs::QuotaJob.get_select_answer_templates2(rule_arr)
	# 	rule_arr.each {|rule| puts "rule_sample_ids ::: #{rule.sample_ids}"}
	# 	assert_equal JSON.parse(select_answer_templates.to_json), JSON.parse(([]).to_json)
	# end
end
