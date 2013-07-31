class MigrateDb


	def self.migrate
		self.migrate_survey
		
	end

	def self.migrate_survey
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
				"reward_scheme_id" => "" }

			# the sms promote related
			s.sms_promotable = false
			s.sms_promote_info = { "sms_amount" => 0,
				"promote_to_undefined_sample" => false,
				"promote_sms_count" => 0,
				"reward_scheme_id" => "" }

			# the browser promote related
			s.broswer_extension_promotable = false
			s.broswer_extension_promote_info = { "login_sample_promote_only" => false,
				"filter" => [[{"key_word" => [""], "url" => ""}]],
				"reward_scheme_id" => "" }

			# the weibo promote related
			s.weibo_promotable = false
			s.weibo_promote_info = { "text" => "",
				"image" => "",
				"video" => "",
				"audio" => "","reward_scheme_id" => "" }

			s.sample_attributes_for_promote = []

			s.save
		end
	end

	def self.migrate_answer
		Answer.all.each do |a|
			# the status field
			if a.status == 0
				a.status = Answer::EDIT
			elsif s.status == 1
				a.status = Answer::REJECT
			elsif s.status == 2
				a.status = Answer::UNDER_REVIEW
			elsif s.status == 3
				a.status = Answer::FINISH
			elsif s.status == 4
				a.status == Answer::REDO
			end
			# the reject type field
			if a.reject_type == 0
				a.reject_type = Answer::REJECT_BY_QUOTA
			elsif reject_type == 1
				a.reject_type = Answer::REJECT_BY_QUALITY_CONTROL
			elsif reject_type == 2
				a.reject_type == Answer::REJECT_BY_REVIEW
			elsif reject_type == 3
				a.reject_type = Answer::REJECT_BY_SCREEN
			elsif reject_type == 4
				a.reject_type = Answer::TIMEOUT
			end
			# the introducer_reward_assigned field
			a.introducer_reward_assigned = a.status == Answer::FINISH
			# the reward_delivered field
			a.reward_delivered = a.status == Answer::FINISH
			# the rewards field
			a.rewards = []
			a.save
		end
	end

	def self.migrate_user
		User.all.each do |u|
			# remove the password_confirmation
			u.password_confirmation = nil
			# the email activation field
			u.email_activation = u.status > 1
			# the email subscribe field
			u.email_subscribe = true
			# the user_role field
			user_role = 1
			user_role += 2 if u.surveys.present?
			user_role += 4 if [16, 32].include?(u.role)
			u.user_role = user_role
			# the status field
			u.status = u.status == 0 ? User::VISITOR : User::REGISTERED
			u.save
		end
	end

	def self.migrate_gift
		Gift.all.each do |g|
			# the type field
			g.type = g.type == 1 ? Gfit::REAL : Gift::VIRTUAL
			# the exchange count field
			g.exchange_count = 0
			# the status field
			g.status = [-1,0].include?(g.status) ? Gift::OFF_THE_SHELF : Gift::ON_THE_SHELF
			g.status = Gift::DELETED if g.is_deleted
			g.save
		end
	end

	def self.migrate_prize
		Prize.all.each do |p|
			# the type field
			g.type = g.type == 1 ? Gfit::REAL : Gift::VIRTUAL
			# the status field
			p.status = p.is_deleted ? Prize::DELETED : Prize::NORMAL
			p.save
		end
	end

	def self.migrate_order
		Order.all.each do |o|
			# the code field
			o.code = o.created_at.strftime("%Y%m%d") + sprintf("%05d",rand(10000))
		end
	end
end