# encoding: utf-8
FactoryGirl.define do
  factory :single_choice_question, class: Question do
    content({"text" => "这是一个单选题",
             "image" => "",
             "audio" => "",
             "video" => ""})
    issue({:choices => [{:input_id => 1,
                         :content => {"text" => "我是一号选项",
                                      "image" => "",
                                      "audio" => "",
                                      "video" => ""},
                         :is_exclusive => true},
                        {:input_id => 2,
                         :content => {"text" => "二号唉",
                                      "image" => "",
                                      "audio" => "",
                                      "video" => ""},
                         :is_exclusive => true},
                        {:input_id => 3,
                         :content => {"text" => "三号!!!",
                                      "image" => "",
                                      "audio" => "",
                                      "video" => ""},
                         :is_exclusive => true}],
           :other_item => {:has_other_item => true,
                           :input_id => 4,
                           :content => {"text" => "四号其它项",
                                        "image" => "",
                                        "audio" => "",
                                        "video" => ""},
                           :is_exclusive => true}
    })
    question_type 0
  end
  factory :multi_choice_question, class: Question do
    content({"text" => "这是一个多选题",
             "image" => "",
             "audio" => "",
             "video" => ""})
    issue({:choices => [{:input_id => 1,
                         :content => {"text" => "我是一号选项",
                                      "image" => "",
                                      "audio" => "",
                                      "video" => ""},
                         :is_exclusive => true},
                        {:input_id => 2,
                         :content => {"text" => "二号唉",
                                      "image" => "",
                                      "audio" => "",
                                      "video" => ""},
                         :is_exclusive => true},
                        {:input_id => 3,
                         :content => {"text" => "三号!!!",
                                      "image" => "",
                                      "audio" => "",
                                      "video" => ""},
                         :is_exclusive => true}],
           :other_item => {:has_other_item => true,
                           :input_id => 4,
                           :content => {"text" => "四号其它项",
                                        "image" => "",
                                        "audio" => "",
                                        "video" => ""},
                           :is_exclusive => true}
    })
    question_type 0
  end
  factory :matrix_choice_question, class: Question do
    content({"text" => "这是一个矩阵选择题",
             "image" => "",
             "audio" => "",
             "video" => ""})
    issue({:choices => [{:input_id => 1,
                         :content => {"text" => "我是一号选项",
                                      "image" => "",
                                      "audio" => "",
                                      "video" => ""},
                         :is_exclusive => true},
                        {:input_id => 2,
                         :content => {"text" => "二号唉",
                                      "image" => "",
                                      "audio" => "",
                                      "video" => ""},
                         :is_exclusive => true},
                        {:input_id => 3,
                         :content => {"text" => "三号!!!",
                                      "image" => "",
                                      "audio" => "",
                                      "video" => ""},
                         :is_exclusive => true}],
           :other_item => {:has_other_item => true,
                           :input_id => 4,
                           :content => {"text" => "四号其它项",
                                        "image" => "",
                                        "audio" => "",
                                        "video" => ""},
                           :is_exclusive => true}
    })
    question_type 0
  end
end