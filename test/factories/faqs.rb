# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :faq do
    faq_type "MyString"
    question "MyString"
    answer "MyString"
  end
end
