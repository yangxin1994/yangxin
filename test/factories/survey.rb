# encoding: utf-8

FactoryGirl.define do 
	factory :survey_with_quota, class: Survey do 
		status 8

		factory :survey_with_quota_1 do
			quota 	({	"rules" => 	[
						{   "conditions" => [
								{"condition_type" => 0, 
								"name" => "tp_q_1", 
								"value" => "male"
								},
								{"condition_type" => 0, 
								"name" => "tp_q_2", 
								"value" => "23"
								},
								{"condition_type" => 1,
								"name" => "tp_q_3", 
								"value" => "apple"
								}
											],
							"amount" => 100
						},
						{   "conditions" => [
								{"condition_type" => 0, 
								"name" => "tp_q_1", 
								"value" => "male"
								},
								{"condition_type" => 0, 
								"name" => "tp_q_2", 
								"value" => "23"
								},
								{"condition_type" => 1,
								"name" => "tp_q_3", 
								"value" => "pear"
								}
											],
							"amount" => 200
						},
						{   "conditions" => [
								{"condition_type" => 0, 
								"name" => "tp_q_1", 
								"value" => "male"
								},
								{"condition_type" => 1,
								"name" => "tp_q_3", 
								"value" => "pear"
								}
											],
							"amount" => 100
						}
								]
					})

			quota_stats ({"answer_number" => [50, 50, 50]})
		end

		factory :survey_with_quota_2 do
			quota 	({	"rules" => 	[
						{   "conditions" => [
								{"condition_type" => 0, 
								"name" => "tp_q_1", 
								"value" => "female"
								},
								{"condition_type" => 0, 
								"name" => "tp_q_2", 
								"value" => "24"
								},
								{"condition_type" => 1,
								"name" => "tp_q_3", 
								"value" => "apple"
								}
											],
							"amount" => 100
						},
						{   "conditions" => [
								{"condition_type" => 0, 
								"name" => "tp_q_1", 
								"value" => "male"
								},
								{"condition_type" => 0, 
								"name" => "tp_q_2", 
								"value" => "23"
								},
								{"condition_type" => 1,
								"name" => "tp_q_3", 
								"value" => "pear"
								}
											],
							"amount" => 200
						},
						{   "conditions" => [
								{"condition_type" => 0, 
								"name" => "tp_q_1", 
								"value" => "female"
								},
								{"condition_type" => 1,
								"name" => "tp_q_3", 
								"value" => "pear"
								}
											],
							"amount" => 100
						}
								]
					})

			quota_stats ({"answer_number" => [50, 100, 50]})
		end
	end
end

FactoryGirl.define do
	factory :jesse_s1, class: Survey do
		title "调查问卷主标题"
		subtitle "调查问卷副标题"
		welcome "调查问卷欢迎语"
		closing "调查问卷结束语"
		header "调查问卷页眉"
		footer "调查问卷页脚"
		description "调查问卷描述"
		created_at {Time.now.to_i}
		updated_at {Time.now.to_i}
		status 0
	end
end
FactoryGirl.define do
	factory :jesse_s2, class: Survey do
		title "调查问卷主标题"
		subtitle "调查问卷副标题"
		welcome "调查问卷欢迎语"
		closing "调查问卷结束语"
		header "调查问卷页眉"
		footer "调查问卷页脚"
		description "调查问卷描述"
		created_at {Time.now.to_i}
		updated_at {Time.now.to_i}
		status 0
	end
end
FactoryGirl.define do
	factory :jesse_s3, class: Survey do
		title "调查问卷主标题"
		subtitle "调查问卷副标题"
		welcome "调查问卷欢迎语"
		closing "调查问卷结束语"
		header "调查问卷页眉"
		footer "调查问卷页脚"
		description "调查问卷描述"
		created_at {Time.now.to_i}
		updated_at {Time.now.to_i}
		status 0
	end
end
FactoryGirl.define do
	factory :closed_survey, class: Survey do
		title "调查问卷主标题"
		subtitle "调查问卷副标题"
		welcome "调查问卷欢迎语"
		closing "调查问卷结束语"
		header "调查问卷页眉"
		footer "调查问卷页脚"
		description "调查问卷描述"
		created_at {Time.now.to_i}
		updated_at {Time.now.to_i}
		status 0
		publish_status 1
	end
end
FactoryGirl.define do
	factory :under_review_survey, class: Survey do
		title "调查问卷主标题"
		subtitle "调查问卷副标题"
		welcome "调查问卷欢迎语"
		closing "调查问卷结束语"
		header "调查问卷页眉"
		footer "调查问卷页脚"
		description "调查问卷描述"
		created_at {Time.now.to_i}
		updated_at {Time.now.to_i}
		status 0
		publish_status 2
	end
end
FactoryGirl.define do
	factory :paused_survey, class: Survey do
		title "调查问卷主标题"
		subtitle "调查问卷副标题"
		welcome "调查问卷欢迎语"
		closing "调查问卷结束语"
		header "调查问卷页眉"
		footer "调查问卷页脚"
		description "调查问卷描述"
		created_at {Time.now.to_i}
		updated_at {Time.now.to_i}
		status 0
		publish_status 4
	end
end
FactoryGirl.define do
	factory :published_survey, class: Survey do
		title "调查问卷主标题"
		subtitle "调查问卷副标题"
		welcome "调查问卷欢迎语"
		closing "调查问卷结束语"
		header "调查问卷页眉"
		footer "调查问卷页脚"
		description "调查问卷描述"
		created_at {Time.now.to_i}
		updated_at {Time.now.to_i}
		status 0
		publish_status 8
	end
end
