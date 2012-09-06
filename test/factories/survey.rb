# encoding: utf-8
FactoryGirl.define do

  factory :survey_with_issue, class: Survey do
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

    status 8
  end
  factory :survey_with_issue_and_answer, class: Answer do
    @survey = FactoryGirl.create(:survey_with_issue)
    @answer_content = {}
    @all_questions_id = @survey.all_questions_id

    @answers = [{"text_input" => "我选择了其它项", "selection" => ""},
                {"text_input" => "我选择了其它项", "selections" => ["1", "3"]},
                ["1", "2"],
                [["1", "2"], ["2"]],
                "我是文本填充题的答案",
                123.456,
                "lalala@cc.com",
                # "http://twitter.com",
                "010 1231212",
                [1012, 9, 3, 2, 4, 2, 60],
                ["北京市", "北京市", "朝阳区", "大屯东路金泉家园", "000000"],
                ["组合文本填充题的答案", 123, "dssds"],
                ["组合文本填充题的答案", 123, "dssds"],
                {"text_input" => "其他项",
                 "1" => 20,
                 "2" => 30,
                 "3" => 20,
                 "4" => 30},
                {"text_input" => "其他项",
                 "sort_result" => ["3", "2", "1"]},
                {"text_input" => "其他项",
                 "1" => 80,
                 "2" => 70,
                 "3" => 50}
               ]
    @answers.each_index do |i|
      @answer_content[@all_questions_id[i].to_s] = @answers[i]
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
