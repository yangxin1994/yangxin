# encoding: utf-8
FactoryGirl.define do
  factory :single_choice_question, class: Question do
    content({:text => "这是一个单选题",
             :image => "",
             :audio => "",
             :video => ""})
    issue({:choices => [{:input_id => "1",
                         :content => {:text => "我是一号选项",
                                      :image => "",
                                      :audio => "",
                                      :video => ""},
                         :is_exclusive => true},
                        {:input_id => "2",
                         :content => {:text => "二号唉",
                                      :image => "",
                                      :audio => "",
                                      :video => ""},
                         :is_exclusive => true},
                        {:input_id => "3",
                         :content => {:text => "三号!!!",
                                      :image => "",
                                      :audio => "",
                                      :video => ""},
                         :is_exclusive => true}],
           :other_item => {:has_other_item => true,
                           :input_id => "4",
                           :content => {:text => "四号其它项",
                                        :image => "",
                                        :audio => "",
                                        :video => ""},
                           :is_exclusive => true},
           :min_choice => 1,
           :max_choice => 1,
           :is_list_style => false,
           :is_rand => false
    })
    question_type 0
  end
  factory :multi_choice_question, class: Question do
    content({:text => "这是一个多选题",
             :image => "",
             :audio => "",
             :video => ""})
    issue({:choices => [{:input_id => "1",
                         :content => {:text => "我是一号选项",
                                      :image => "",
                                      :audio => "",
                                      :video => ""},
                         :is_exclusive => true},
                        {:input_id => "2",
                         :content => {:text => "二号唉",
                                      :image => "",
                                      :audio => "",
                                      :video => ""},
                         :is_exclusive => true},
                        {:input_id => "3",
                         :content => {:text => "三号!!!",
                                      :image => "",
                                      :audio => "",
                                      :video => ""},
                         :is_exclusive => true}],
           :other_item => {:has_other_item => true,
                           :input_id => "4",
                           :content => {:text => "四号其它项",
                                        :image => "",
                                        :audio => "",
                                        :video => ""},
                           :is_exclusive => true},
           :min_choice => 1,
           :max_choice => 3,
           :is_list_style => false,
           :is_rand => false
    })
    question_type 0
  end

  factory :matrix_singel_choice_question, class: Question do
    content({:text => "这是一个矩阵单项选择题",
             :image => "",
             :audio => "",
             :video => ""})
    issue({:choices => [{:input_id => "1",
                         :content => {:text => "我是一号选项",
                                      :image => "",
                                      :audio => "",
                                      :video => ""},
                         :is_exclusive => true},
                        {:input_id => "2",
                         :content => {:text => "二号唉",
                                      :image => "",
                                      :audio => "",
                                      :video => ""},
                         :is_exclusive => true},
                        {:input_id => "3",
                         :content => {:text => "三号!!!",
                                      :image => "",
                                      :audio => "",
                                      :video => ""},
                         :is_exclusive => true},
                        {:input_id => "4",
                         :content => {:text => "四号!!!",
                                      :image => "",
                                      :audio => "",
                                      :video => ""},
                         :is_exclusive => true}],
           :choice_num_per_row => 2,
           :show_style => 0,
           :row_name => ["第一行", "第二行"],
           :row_id => ["1", "2"],
           :is_row_rand => false,
           :row_num_per_group => -1,
           :min_choice => 1,
           :max_choice => 1,
           :is_list_style => false,
           :is_rand => false  
    })
    question_type 1
  end
  factory :matrix_mutil_choice_question, class: Question do
    content({:text => "这是一个矩阵多项选择题",
             :image => "",
             :audio => "",
             :video => ""})
    issue({:choices => [{:input_id => "1",
                         :content => {:text => "我是一号选项",
                                      :image => "",
                                      :audio => "",
                                      :video => ""},
                         :is_exclusive => true},
                        {:input_id => "2",
                         :content => {:text => "二号唉",
                                      :image => "",
                                      :audio => "",
                                      :video => ""},
                         :is_exclusive => true},
                        {:input_id => "3",
                         :content => {:text => "三号!!!",
                                      :image => "",
                                      :audio => "",
                                      :video => ""},
                         :is_exclusive => true},
                        {:input_id => "4",
                         :content => {:text => "四号!!!",
                                      :image => "",
                                      :audio => "",
                                      :video => ""},
                         :is_exclusive => true}],
           :choice_num_per_row => 2,
           :show_style => 0,
           :row_name => ["第一行", "第二行"],
           :row_id => ["1", "2"],
           :is_row_rand => false,
           :row_num_per_group => -1,
           :min_choice => 1,
           :max_choice => 3,
           :is_list_style => false,
           :is_rand => false  
    })
    question_type 1
  end
  factory :text_blank_choice_question, class: Question do
    content({:text => "这是一个文本填充题",
             :image => "",
             :audio => "",
             :video => ""})
    issue({:min_length => 10,
           :max_length => 140,
           :has_multiple_line => true,
           :size => 1})
    question_type 2
  end
  factory :number_blank_choice_question, class: Question do
    content({:text => "这是一个数值填充题",
             :image => "",
             :audio => "",
             :video => ""})
    issue({:precision => 2,
           :min_value => 1,
           :max_value => 80000,
           :unit => "$",
           :unit_location => 1})
    question_type 3
  end
  factory :email_blank_choice_question, class: Question do
    content({:text => "这是一个邮箱填充题",
             :image => "",
             :audio => "",
             :video => ""})
    issue({})
    question_type 4
  end
  factory :phone_blank_choice_question, class: Question do
    content({:text => "这是一个电话填充题",
             :image => "",
             :audio => "",
             :video => ""})
    issue({:phone_type => 1})
    question_type 5
  end
  factory :time_blank_choice_question, class: Question do
    content({:text => "这是一个时间填充题",
             :image => "",
             :audio => "",
             :video => ""})
    issue({:format => 127,
           :min_time => -1,
           :max_time => -1})
    question_type 6
  end
  factory :address_blank_choice_question, class: Question do
    content({:text => "这是一个电话填充题",
             :image => "",
             :audio => "",
             :video => ""})
    issue({:phone_type => 1})
    question_type 7
  end
  factory :blank_choice_question, class: Question do
    content({:text => "这是一个电话填充题",
             :image => "",
             :audio => "",
             :video => ""})
    issue({:phone_type => 1})
    question_type 8
  end
  factory :matrix_blank_choice_question, class: Question do
    content({:text => "这是一个电话填充题",
             :image => "",
             :audio => "",
             :video => ""})
    issue({:phone_type => 1})
    question_type 9
  end
end