namespace :migration do
	desc "set the field of finished_at for all answers"
	task 'set_finished_at_for_all_answers' => :environment do
		Answer.all.each do |a|
			begin
				if a.status == 1
					if a.finished_at.nil?
						if a.rejected_at.nil?
							a.finished_at = Time.now.to_i
						else
							a.finished_at = a.rejected_at
						end
					end
				elsif a.status == 2
					if a.finished_at.nil?
						a.finished_at = Time.now.to_i
					end
				end
			rescue
				a.finished_at = Time.now.to_i
			end
			a.save
		end
	end
end
