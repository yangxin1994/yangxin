# coding: utf-8
require 'test_helper'

class QuotaJobTest < ActiveSupport::TestCase

	test "01 should get rule arr from check_quota" do 
			clear(Survey)

			assert Jobs::QuotaJob.methods.include?(:check_quota)
			assert_equal Survey.all.count, 0
			quota_hash = {	"rules" => 	[
								{   "conditions" => [
										{"condition_type" => 0, 
										"name" => "sample_id1", 
										"value" => "male"
										},
										{"condition_type" => 0, 
										"name" => "sample_id2", 
										"value" => "23"
										},
										{"condition_type" => 1,
										"name" => "sample_id3", 
										"value" => "apple"
										}
													],
									"amount" => 100
								},
								{   "conditions" => [
										{"condition_type" => 0, 
										"name" => "sample_id1", 
										"value" => "male"
										},
										{"condition_type" => 0, 
										"name" => "sample_id2", 
										"value" => "23"
										},
										{"condition_type" => 1,
										"name" => "sample_id3", 
										"value" => "pear"
										}
													],
									"amount" => 200
								},
								{   "conditions" => [
										{"condition_type" => 0, 
										"name" => "sample_id1", 
										"value" => "male"
										},
										{"condition_type" => 1,
										"name" => "sample_id3", 
										"value" => "pear"
										}
													],
									"amount" => 100
								},
										]
							}
		quota_stats = {"answer_number" => [50, 50, 50]}
		survey = Survey.create({"quota" => quota_hash, "status" => 8, "quota_stats" => quota_stats})
		assert_equal Survey.all.count, 1
		survey = Survey.first
		assert_not_equal survey, nil
		assert_equal survey.quota, quota_hash

		assert_equal Survey.where(status: 8).count, 1
		conditions = []
		conditions << Jobs::Condition.new("sample_id1", "male")
		conditions << Jobs::Condition.new("sample_id2", "23")
		rule1 = Jobs::Rule.new(Survey.first.id, 0, conditions, 200)
		conditions = []
		conditions << Jobs::Condition.new("sample_id1", "male")
		rule2 = Jobs::Rule.new(Survey.last.id, 0, conditions, 50)
		assert_equal Jobs::QuotaJob.check_quota.to_json, ([] << rule1 << rule2).to_json

		clear(Survey)
	end
end
