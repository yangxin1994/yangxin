# encoding: utf-8
FactoryGirl.define do

  factory :survey_with_issue, class: Survey do
    title "我是用来做导出的"
    subtitle "伤不起的问卷啊"
    welcome "欢迎词"
    closing "终于结束了么"
    header "我是页眉"
    footer "页脚"
    description "描述哦"
    pages [{name: "仅有的一页",
            questions: [FactoryGirl.create(:single_choice_question).id,
                        FactoryGirl.create(:multi_choice_question).id,
                        FactoryGirl.create(:matrix_singel_choice_question).id,
                        FactoryGirl.create(:matrix_mutil_choice_question).id,
                        FactoryGirl.create(:text_blank_choice_question).id,
                        FactoryGirl.create(:number_blank_choice_question).id,
                        FactoryGirl.create(:email_blank_choice_question).id,
                        #FactoryGirl.create(:url_blank_choice_question).id,
                        FactoryGirl.create(:phone_blank_choice_question).id,
                        FactoryGirl.create(:time_blank_choice_question).id,
                        FactoryGirl.create(:address_blank_choice_question).id,
                        FactoryGirl.create(:blank_choice_question).id,
                        FactoryGirl.create(:matrix_blank_choice_question).id
              ]}
    ]
    status 8
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
