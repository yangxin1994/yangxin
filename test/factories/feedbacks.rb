# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :feedback do
    feedback_type "MyString"
    title "MyString"
    content "MyString"
    is_answer ""
  end
end
