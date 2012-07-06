# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :public_notice do
    title "MyString"
    content "MyString"
    attachment "MyString"
    public_notice_type "MyString"
  end
end
