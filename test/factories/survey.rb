# coding: utf-8

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
  

  factory :survey_with_issue, class: Survey do
    @quota_questions = [FactoryGirl.create(:text_blank_question).id]
    @questions1 = [FactoryGirl.create(:single_choice_question).id,
                  FactoryGirl.create(:multi_choice_question).id,
                  FactoryGirl.create(:matrix_singel_choice_question).id,
                  FactoryGirl.create(:matrix_mutil_choice_question).id,
                  FactoryGirl.create(:text_blank_question).id,
                  FactoryGirl.create(:number_blank_question).id,
                  FactoryGirl.create(:email_blank_question).id,
                  FactoryGirl.create(:url_blank_question).id
              ]
    @questions2 = [FactoryGirl.create(:phone_blank_question).id,
                  FactoryGirl.create(:time_blank_question).id,
                  FactoryGirl.create(:address_blank_question).id,
                  FactoryGirl.create(:blank_question).id,
                  FactoryGirl.create(:table_question).id,
                  FactoryGirl.create(:matrix_blank_question).id,
                  FactoryGirl.create(:const_sum_question).id,
                  FactoryGirl.create(:sort_question).id,
                  FactoryGirl.create(:rank_question).id
              ]
    title "我是用来做导出的"
    subtitle "伤不起的问卷啊"
    welcome "欢迎词"
    closing "终于结束了么"
    header "我是页眉"
    footer "页脚"
    description "描述哦"
    pages [{name: "第一页",
            questions: @questions1 },
           {name: "别挣扎了...我是第二页",
            questions: @questions2 }
    ]
    quota_template_question_page @quota_questions
    status 8
  end
  factory :answer_with_issue, class: Answer do
    @survey = FactoryGirl.create(:survey_with_issue)
    @answer_content = {}
    @all_questions_with_quota_id = @survey.all_quota_questions_id + @survey.all_questions_id
    # 所有的其他项必须是最后一个,这是答案分析的结构决定的
    #@quota_answers = ["我是一个质控题"]
    @answers = ["我是一个质控题",
                {"text_input" => "我选择了其它项", "selection" => []},
                {"text_input" => "我选择了其它项", "selections" => ["1", "3","6","10"]},
                ["1", "2", "6"],
                [["1", "2"], ["2", "7"]],
                "我是文本填充题的答案",
                123456,
                "lalala@cc.com",
                "http://twitter.com",
                "010 1231212",
                [1012, 9, 3, 2, 4, 2, 60],
                ["北京市", "北京市", "朝阳区", "大屯东路金泉家园", "000000"],
                ["组合文本填充题的答案", 123.123, "0312 4566456"],
                ["foobar@gmail.com", "www.google.com", ["北京市", "北京市", "朝阳区", "大屯东路金泉家园", "000000"]],
                [["foobar@gmail.com", "www.google.com", "www.baidu.com", ["北京市", "北京市", "朝阳区", "大屯东路金泉家园", "000000"]],
                ["foobar@qq.com", "www.bing.com", "www.yahoo.com", ["北京市", "北京市", "Laaa", "大屯东路金泉家园", "000000"]],
                ["foobar@qq.com", "www.bing.com", "www.yahoo.com", ["北京市", "北京市", "Laaa", "大屯东路金泉家园", "000000"]]],
                {"text_input" => "其他项",
                 "1" => 0,
                 "2" => 5,
                 "3" => 10,
                 "4" => 3,
                 "5" => 20,
                 "6" => 25,
                 "7" => 30,
                 "8" => 7},
                {"text_input" => "其他项",
                 "sort_result" => ["8", "2", "1", "4", "5", "3", "6", "7", "9"]},
                {"text_input" => "其他项",
                 "7" => 80,
                 "9" => 70,
                 "3" => 30,
                 "4" => 60,
                 "1" => 20,
                 "2" => 30,
                 "5" => 90,
                 "8" => 30,
                 "6" => 30}
               ]
    @answers2 = [{"text_input" => "other", "selection" => []},
                {"text_input" => "other", "selections" => ["1", "3"]},
                ["1", "2"],
                [["1", "2"], ["2"]],
                "text_blank_question",
                123.456,
                "lalala@cc.com",
                "http://twitter.com",
                "010 1231212",
                [1012, 9, 3, 2, 4, 2, 60],
                ["beijing", "beijing", "chaoyang", "jinquanjiayuan", "000000"],
                ["table_question", 123.123, "0312 4566456"],
                ["foobar@gmail.com", "www.google.com", ["beijing", "beijing", "chaoyang", "jinquanjiayuan", "000000"]],
                [["foobar@gmail.com", "www.google.com", "www.baidu.com", ["beijing", "beijing", "chaoyang", "jinquanjiayuan", "000000"]],
                ["foobar@qq.com", "www.bing.com", "www.yahoo.com", ["beijing", "beijing", "Laaa", "jinquanjiayuan", "000000"]],
                ["foobar@qq.com", "www.bing.com", "www.yahoo.com", ["beijing", "beijing", "Laaa", "jinquanjiayuan", "000000"]]],
                {"text_input" => "other",
                 "1" => 20,
                 "2" => 30,
                 "3" => 20,
                 "4" => 30},
                {"text_input" => "other",
                 "sort_result" => ["8", "2", "1", "4"]},
                {"text_input" => "other",
                 "7" => 80,
                 "9" => -1,
                 "3" => 30,
                 "4" => 60}
               ]

    @answers.each_index do |i|
      @answer_content[@all_questions_with_quota_id[i].to_s] = @answers[i]
    end
    status 2
    finish_type 1
    channel -1
    answer_content @answer_content
    #template_answer_content
  end

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
