FactoryGirl.define do
  factory :increase_point, class: RewardLog do
  	point 500
  	type 2
  	cause 1 #AdminOperate
    operator factory: :admin_foo
    user factory: :user_bar
    
  end
end