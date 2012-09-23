# coding: utf-8
include QuestionTypeEnum
FactoryGirl.define do
  factory :single_choice_question, class: Question do
    content({:text => "这是一个单选题",
             :image => [],
             :audio => [],
             :video => []})
    issue({:choices => [{:input_id => "1",
                         :content => {:text => "我是一号选项",
                                      :image => [],
                                      :audio => [],
                                      :video => []},
                         :is_exclusive => true},
                        {:input_id => "2",
                         :content => {:text => "二号唉",
                                      :image => [],
                                      :audio => [],
                                      :video => []},
                         :is_exclusive => true},
                        {:input_id => "3",
                         :content => {:text => "三号!!!",
                                      :image => [],
                                      :audio => [],
                                      :video => []},
                         :is_exclusive => true}],
           :other_item => {:has_other_item => true,
                           :input_id => "4",
                           :content => {:text => "四号其它项",
                                        :image => [],
                                        :audio => [],
                                        :video => []},
                           :is_exclusive => true},
           :min_choice => 1,
           :max_choice => 1,
           :is_list_style => false,
           :is_rand => false
    })
    question_type CHOICE_QUESTION
  end
  factory :multi_choice_question, class: Question do
    content({:text => "这是一个多选题",
             :image => [],
             :audio => [],
             :video => []})
    issue({:choices => [{:input_id => "1",
                         :content => {:text => "我是一号选项",
                                      :image => [],
                                      :audio => [],
                                      :video => []},
                         :is_exclusive => true},
                        {:input_id => "2",
                         :content => {:text => "二号唉",
                                      :image => [],
                                      :audio => [],
                                      :video => []},
                         :is_exclusive => true},
                        {:input_id => "3",
                         :content => {:text => "三号!!!",
                                      :image => [],
                                      :audio => [],
                                      :video => []},
                         :is_exclusive => true}],
           :other_item => {:has_other_item => true,
                           :input_id => "4",
                           :content => {:text => "四号其它项",
                                        :image => [],
                                        :audio => [],
                                        :video => []},
                           :is_exclusive => true},
           :min_choice => 1,
           :max_choice => 3,
           :is_list_style => false,
           :is_rand => false
    })
    question_type CHOICE_QUESTION
  end

  factory :matrix_singel_choice_question, class: Question do
    content({:text => "这是一个矩阵单项选择题",
             :image => [],
             :audio => [],
             :video => []})
    issue({:choices => [{:input_id => "1",
                         :content => {:text => "我是一号选项",
                                      :image => [],
                                      :audio => [],
                                      :video => []},
                         :is_exclusive => true},
                        {:input_id => "2",
                         :content => {:text => "二号唉",
                                      :image => [],
                                      :audio => [],
                                      :video => []},
                         :is_exclusive => true},
                        {:input_id => "3",
                         :content => {:text => "三号!!!",
                                      :image => [],
                                      :audio => [],
                                      :video => []},
                         :is_exclusive => true},
                        {:input_id => "4",
                         :content => {:text => "四号!!!",
                                      :image => [],
                                      :audio => [],
                                      :video => []},
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
    question_type MATRIX_CHOICE_QUESTION
  end
  factory :matrix_mutil_choice_question, class: Question do
    content({:text => "这是一个矩阵多项选择题",
             :image => [],
             :audio => [],
             :video => []})
    issue({:choices => [{:input_id => "1",
                         :content => {:text => "我是一号选项",
                                      :image => [],
                                      :audio => [],
                                      :video => []},
                         :is_exclusive => true},
                        {:input_id => "2",
                         :content => {:text => "二号唉",
                                      :image => [],
                                      :audio => [],
                                      :video => []},
                         :is_exclusive => true},
                        {:input_id => "3",
                         :content => {:text => "三号!!!",
                                      :image => [],
                                      :audio => [],
                                      :video => []},
                         :is_exclusive => true},
                        {:input_id => "4",
                         :content => {:text => "四号!!!",
                                      :image => [],
                                      :audio => [],
                                      :video => []},
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
    question_type MATRIX_CHOICE_QUESTION
  end
  factory :text_blank_question, class: Question do
    content({:text => "这是一个文本填充题",
             :image => [],
             :audio => [],
             :video => []})
    issue({:min_length => 10,
           :max_length => 140,
           :has_multiple_line => true,
           :size => 1})
    question_type TEXT_BLANK_QUESTION
  end
  factory :number_blank_question, class: Question do
    content({:text => "这是一个数值填充题",
             :image => [],
             :audio => [],
             :video => []})
    issue({:precision => 2,
           :min_value => 1,
           :max_value => 80000,
           :unit => "$",
           :unit_location => 1})
    question_type NUMBER_BLANK_QUESTION
  end
  factory :email_blank_question, class: Question do
    content({:text => "这是一个邮箱填充题",
             :image => [],
             :audio => [],
             :video => []})
    issue({})
    question_type EMAIL_BLANK_QUESTION
  end
  factory :url_blank_question, class: Question do
    content({:text => "这是一个链接填充题",
             :image => [],
             :audio => [],
             :video => []})
    issue({})
    question_type URL_BLANK_QUESTION
  end
  factory :phone_blank_question, class: Question do
    content({:text => "这是一个电话填充题",
             :image => [],
             :audio => [],
             :video => []})
    issue({:phone_type => 1})
    question_type PHONE_BLANK_QUESTION
  end
  factory :time_blank_question, class: Question do
    content({:text => "这是一个时间填充题",
             :image => [],
             :audio => [],
             :video => []})
    issue({:format => 127,
           :min_time => -1,
           :max_time => -1})
    question_type TIME_BLANK_QUESTION
  end
  factory :address_blank_question, class: Question do
    content({:text => "这是一个地址填充题",
             :image => [],
             :audio => [],
             :video => []})
    issue({:has_postcode => true,
           :format => 15})
    question_type ADDRESS_BLANK_QUESTION
  end
  factory :blank_question, class: Question do
    content({:text => "这是一个组合填充题",
             :image => [],
             :audio => [],
             :video => []})
    issue({:is_rand => false,
           :inputs => [{:input_id => "1",
                        :content => {:text => "这是一个文本填充题",
                                     :image => [],
                                     :audio => [],
                                     :video => []},
                        :data_type => "Text",
                        :properties => {:min_length => 1,
                                        :max_length => 20,
                                        :has_multiple_line => false,
                                        :size => 1}},
                       {:input_id => "2",
                        :content => {:text => "这是一个数字填充题",
                                     :image => [],
                                     :audio => [],
                                     :video => []},
                        :data_type => "Number",
                        :properties => {:precision => 2,
                                        :min_value => 1,
                                        :max_value => 80000,
                                        :unit => "$",
                                        :unit_location => 1}},
                       {:input_id => "3",
                        :content => {:text => "这是一个电话填充题",
                                     :image => [],
                                     :audio => [],
                                     :video => []},
                        :data_type => "Number",
                        :properties => { :phone_type => 1}}
                      ],
           :show_style => 0})
    question_type BLANK_QUESTION
  end
  factory :table_question, class: Question do
    content({:text => "这是一个循环填充题",
             :image => [],
             :audio => [],
             :video => []})
    issue({:is_rand => false,
           :inputs => [{:input_id => "1",
                        :content => {:text => "这是一个邮件填充题",
                                     :image => [],
                                     :audio => [],
                                     :video => []},
                                     :data_type => "Email",
                                     :properties => "nil"},
                       {:input_id => "2",
                        :content => {:text => "这是一个链接填充题",
                                     :image => [],
                                     :audio => [],
                                     :video => []},
                                     :data_type => "Url",
                                     :properties => "nil"},
                       {:input_id => "3",
                        :content => {:text => "这是一个地址填充题",
                                     :image => [],
                                     :audio => [],
                                     :video => []},
                                     :data_type => "Address",
                                     :properties => {:has_postcode => false,
                                                     :format => 15
                                      }}],
           :show_style => 0})
    question_type TABLE_QUESTION
  end
  factory :matrix_blank_question, class: Question do
    content({:text => "这是一个矩阵填充题",
             :image => [],
             :audio => [],
             :video => []})
    issue({:is_rand => false,
           :inputs => [{:input_id => "1",
                        :content => {:text => "这是一个邮件填充题",
                                     :image => [],
                                     :audio => [],
                                     :video => []},
                                     :data_type => "Email",
                                     :properties => "nil"},
                       {:input_id => "2",
                        :content => {:text => "这是一个链接填充题",
                                     :image => [],
                                     :audio => [],
                                     :video => []},
                                     :data_type => "Url",
                                     :properties => "nil"},
                       {:input_id => "3",
                        :content => {:text => "这是一个链接填充题",
                                     :image => [],
                                     :audio => [],
                                     :video => []},
                                     :data_type => "Url",
                                     :properties => "nil"},
                       {:input_id => "4",
                        :content => {:text => "这是一个地址填充题",
                                     :image => [],
                                     :audio => [],
                                     :video => []},
                                     :data_type => "Address",
                                     :properties => {:has_postcode => false,
                                                     :format => 15
                                      }}],
           :show_style => 1,
           :row_name => ["一", "二", "三"],
           :row_id => ["1", "2", "3"],
           :is_row_rand => false,
           :row_number_per_group => -1})
    question_type MATRIX_BLANK_QUESTION
  end
  factory :const_sum_question, class: Question do
    content({:text => "这是一个比重题",
             :image => [],
             :audio => [],
             :video => []})
    issue({:is_rand => false,
           :items => [{:input_id => "1",
                        :content => {:text => "选项1",
                                     :image => [],
                                     :audio => [],
                                     :video => []}},
                      {:input_id => "2",
                        :content => {:text => "选项2",
                                     :image => [],
                                     :audio => [],
                                     :video => []}},
                      {:input_id => "3",
                        :content => {:text => "选项3",
                                     :image => [],
                                     :audio => [],
                                     :video => []}}],
           :other_item => {:has_other_item => true,
                           :input_id => "4",
                           :content => {:text => "四号其它项",
                                        :image => [],
                                        :audio => [],
                                        :video => []}},
           :sum => 100})
    question_type CONST_SUM_QUESTION
  end
  factory :sort_question, class: Question do
    content({:text => "这是一个排序题",
             :image => [],
             :audio => [],
             :video => []})
    issue({:is_rand => false,
           :items => [{:input_id => "1",
                      :content => {:text => "这是一个文本填充题",
                                   :image => [],
                                   :audio => [],
                                   :video => []}},
                      {:input_id => "2",
                       :content => {:text => "这是一个数字填充题",
                                    :image => [],
                                    :audio => [],
                                    :video => []}},
                      {:input_id => "3",
                       :content => {:text => "这是一个电话填充题",
                                    :image => [],
                                    :audio => [],
                                    :video => []}}],
           :other_item => {:has_other_item => true,
                           :input_id => "4",
                           :content => {:text => "四号其它项",
                                        :image => [],
                                        :audio => [],
                                        :video => []}},
           :min => 1,
           :max => 4})
    question_type SORT_QUESTION
  end
  factory :rank_question, class: Question do
    content({:text => "这是一个评分题",
             :image => [],
             :audio => [],
             :video => []})
    issue({:is_rand => false,
           :items => [{:input_id => "1",
                       :content => {:text => "这是一个文本填充题",
                                    :image => [],
                                    :audio => [],
                                    :video => []},
                      :has_unknow => true},
                      {:input_id => "2",
                       :content => {:text => "这是一个地址填充题",
                                    :image => [],
                                    :audio => [],
                                    :video => []},
                      :has_unknow => true},
                      {:input_id => "3",
                       :content => {:text => "这是一个数字填充题",
                                    :image => [],
                                    :audio => [],
                                    :video => []},
                      :has_unknow => false}],
           :other_item => {:has_other_item => true,
                           :input_id => "4",
                           :content => {:text => "四号其它项",
                                        :image => [],
                                        :audio => [],
                                        :video => []}},
           :min => 1,
           :max => 4})
    question_type RANK_QUESTION
  end
end