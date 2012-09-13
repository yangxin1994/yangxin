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
		conditions << Jobs::Condition.new("tp_q_1", "male", true)
		conditions << Jobs::Condition.new("tp_q_2", "23", true)
		rule1 = Jobs::Rule.new(Survey.first.id, conditions, 200)
		conditions = []
		conditions << Jobs::Condition.new("tp_q_1", "male", true)
		rule2 = Jobs::Rule.new(Survey.last.id, conditions, 50)

		# puts "check_quota ............"
		# assert_equal Jobs::QuotaJob.check_quota.to_json, ([] << rule1 << rule2).to_json
		assert_equal Jobs::QuotaJob.check_quota.to_json, [].to_json

		clear(Survey)
	end

	# test "02 should get_select_answer_templates"  do
	# 	clear(Survey)

	# 	assert Jobs::QuotaJob.methods.include?(:check_quota)
	# 	assert_equal Survey.all.count, 0
	# 	FactoryGirl.create(:survey_with_quota_1)
	# 	FactoryGirl.create(:survey_with_quota_2)
	# 	assert_equal Survey.where(status: 8).count, 2

	# 	rule_arr = Jobs::QuotaJob.check_quota
	# 	puts "***********before rule***********"
	# 	rule_arr.each {|rule| puts "before rule ::: #{rule.to_s}"}
	# 	puts "*************get_select_answer_templates2*********"
	# 	select_answer_templates = Jobs::QuotaJob.get_select_answer_templates(rule_arr)
	# 	puts "*********after rules*************"
	# 	rule_arr.each {|rule| puts "after rule ::: #{rule.to_s}"}
	# 	puts "***********select_answer_templates***********"
	# 	select_answer_templates.each {|template| puts "template ::: #{template.to_s}"}
	# 	puts "**********Sample.all.*******************"
	# 	Jobs::Sample.all.each{|template| puts "template ::: #{template.to_s}"}
	# 	assert_equal JSON.parse(select_answer_templates.to_json), JSON.parse(([]).to_json)

	# 	Jobs::QuotaJob.send_emails(select_answer_templates)
	# end
end
