# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :subscriber do
    email ""
    status ""
    is_deleted ""
  end
end
