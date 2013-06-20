FactoryGirl.define do
	factory :lottery_log, class: Log do |f|
		f.type 2
		f.sequence(:data) do |n|
			{
				"result" => n%2 == 0,
				"order_id" => n.to_s,
				"prize_name" => "prize#{n.to_s}"
			}
		end
	end

	factory :redeem_log, class: Log do |f|
		f.type 4
		f.sequence(:data) do |n|
			{
				"amount" => n,
				"order_id" => n.to_s,
				"gift_name" => "gift#{n.to_s}"
			}
		end
	end

	factory :point_log, class: Log do |f|
		f.type 8
		f.sequence(:data) do |n|
			{
				"amount" => n,
				"reason" => n%2 + 1,
				"survey_title" => "the #{n.to_s}th survey"
			}
		end
	end
end