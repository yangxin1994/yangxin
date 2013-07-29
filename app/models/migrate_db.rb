class MigrateDb


	def self.migrate
		self.migrate_survey
		
	end

	def self.migrate_survey
		# survey
		Survey.all.each do |s|
			# the status field
			if s.status == -1
				s.status = Survey::DELETED
			elsif [1,4].include?(s.publish_status)
				s.status = Survey::CLOSED
			else
				s.status = Survey::PUBLISHED
			end

			# the quillme promote related
			s.quillme_promotable = s.show_in_community
			reward_scheme_setting = { "name" => "default scheme",
				"rewards" => [],
				"need_review" => s.answer_need_review }
			if s.point > 0
				reward_scheme_setting["rewards"] << {"type" => RewardScheme::POINT, "amount" => s.point }
			end
			RewardScheme.create_reward_scheme(s, reward_scheme_setting)
			reward_scheme = s.reward_schemes[0]
			s.quillme_promote_info = { "reward_scheme_id" => reward_scheme._id.to_s }
			s.quillme_promote_reward_type = 0

			# the email promote related
			s.email_promotable = false
			s.email_promote_info = { "email_amount" => 0,
				"promote_to_undefined_sample" => false,
				"promote_email_count" => s.email_histories.length,
				"reward_scheme_id" => reward_scheme._id.to_s }


		end
	end
end