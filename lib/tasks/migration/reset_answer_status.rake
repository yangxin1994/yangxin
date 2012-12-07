namespace :migration do
	desc "reset the status of answers"
	task 'reset_answer_status' => :environment do
		Answer.all.each do |a|
			begin
				if a.status > 1
					a.status = a.status + 1
					a.save
				end
				if a.is_reject
					a.reject_type = a.reject_type + 1 if a.reject_type > 1
				elsif a.is_finish
					if a.finish_type == 0
						a.set_under_review
					elsif a.finish_type == 2
						a.set_reject
						a.reject_status = 2
					end
				end
			rescue
			end
		end
	end
end
