#encoding: utf-8
class MigrateDb

	def self.migrate
		self.migrate_point_log
		self.migrate_gift
		self.migrate_prize
		self.migrate_order
		self.migrate_answer
		self.migrate_survey
		self.migrate_user
	end

	def self.migrate_survey
		puts "Migrating surveys......"
		update_time = Time.now
		Survey.where(:updated_at.lt => update_time).each_with_index do |s, index|
			puts index if index%10 == 0
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
			s.quillme_promote_reward_type = 0
			if s.point > 0
				reward_scheme_setting["rewards"] << {"type" => RewardScheme::POINT, "amount" => s.point }
				s.quillme_promote_reward_type = RewardScheme::POINT
			end
			RewardScheme.create_reward_scheme(s, reward_scheme_setting)
			reward_scheme = s.reward_schemes[0]
			s.quillme_promote_info = { "reward_scheme_id" => reward_scheme._id.to_s }


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
		puts "Migrating answers......"
		update_time = Time.now
		Answer.where(:updated_at.lt => update_time).each_with_index do |a, index|
			puts index if index%100 == 0
			# the status field
			if a.status == 0
				a.status = Answer::EDIT
			elsif a.status == 1
				a.status = Answer::REJECT
			elsif a.status == 2
				a.status = Answer::UNDER_REVIEW
			elsif a.status == 3
				a.status = Answer::FINISH
			elsif a.status == 4
				a.status == Answer::REDO
			end
			# the reject type field
			if a.reject_type == 0
				a.reject_type = Answer::REJECT_BY_QUOTA
			elsif a.reject_type == 1
				a.reject_type = Answer::REJECT_BY_QUALITY_CONTROL
			elsif a.reject_type == 2
				a.reject_type == Answer::REJECT_BY_REVIEW
			elsif a.reject_type == 3
				a.reject_type = Answer::REJECT_BY_SCREEN
			elsif a.reject_type == 4
				a.reject_type = Answer::REJECT_BY_TIMEOUT
			end
			# the introducer_reward_assigned field
			a.introducer_reward_assigned = a.status == Answer::FINISH
			# the reward_delivered field
			a.reward_delivered = a.status == Answer::FINISH
			# the rewards field
			a.rewards = []
			# the need review field
			a.need_review = a.survey.try(:answer_need_review)
			a.save
		end
	end

	def self.migrate_user
		puts "Migrating users......"
		update_time = Time.now
		User.where(:updated_at.lt => update_time).each_with_index do |u, index|
			puts index if index%10 == 0
			# remove the password_confirmation
			u.password_confirmation = nil if u.read_attribute("password_confirmation").present?
			# the email activation field
			u.email_activation = u.status > 1
			# the email subscribe field
			u.email_subscribe = true
			# the user_role field
			user_role = 1
			user_role += 2 if u.surveys.present?
			user_role += 4 if (u.role.to_i & 32) > 0 || (u.role.to_i & 16) > 0
			u.user_role = user_role
			# the status field
			u.status = u.status == 0 ? User::VISITOR : User::REGISTERED
			u.save
		end
	end

	def self.migrate_gift
		puts "Migrating gifts......"
		Gift.destroy_all
		BasicGift.all.each_with_index do |bg, index|
			puts index if index%10 == 0
			next if bg._type != "Gift"
			g = Gift.new
			# the type field
			g.type = bg.type == 1 ? Gift::REAL : Gift::VIRTUAL
			# the exchange count field
			g.exchange_count = 0
			# the status field
			g.status = [-1,0].include?(bg.status) ? Gift::OFF_THE_SHELF : Gift::ON_THE_SHELF
			g.status = Gift::DELETED if bg.is_deleted
			# the title field
			g.title = bg.title
			# the description field
			g.description = bg.description
			g.save
			# the photo association
			g.photo = bg.photo
			# the point field
			g.point = bg.point
			# the price field
			g.price = bg.point / 100
			# record the previous basic_gift_id
			g.write_attribute(:basic_gift_id, bg._id.to_s)
			g.save
		end
	end

	def self.migrate_prize
		puts "Migrating prizes......"
		Prize.destroy_all
		BasicGift.all.each_with_index do |bg, index|
			puts index if index%10 == 0
			next if bg._type != "Prize"
			p = Prize.new
			# the type field
			p.type = bg.type == 1 ? Gift::REAL : Gift::VIRTUAL
			# the status field
			p.status = bg.is_deleted ? Prize::DELETED : Prize::NORMAL
			# the title field
			p.title = bg.title
			# the description field
			p.description = bg.description
			p.save
			# the photo association
			p.photo = bg.photo
			# record the previous basic_gift_id
			p.write_attribute(:basic_gift_id, bg._id.to_s)
			p.save
		end
	end

	def self.migrate_order
		puts "Migrating orders......"
		update_time = Time.now
		Order.where(:updated_at.lt => update_time).each_with_index do |o, index|
			puts index if index%100 == 0
			# the code field
			o.code = o.created_at.strftime("%Y%m%d") + sprintf("%05d",rand(10000))
			lottery_code_id = o.read_attribute("lottery_code_id")
			if lottery_code_id.nil?
				# this is a redeem order
				# the source field
				o.source = Order::REDEEM_GIFT
				gift_id = o.gift_id.to_s
				gift = Gift.where(:basic_gift_id => gift_id)[0]
				# the type field
				o.type = gift.type == Gift::REAL ? Order::REAL_GOOD : Order::VIRTUAL_GOOD
				# the gift association
				o.gift_id = gift._id
				# the point field
				o.point = gift.point
			else
				# this is a lottery order
				# the source field
				o.source = Order::WIN_IN_LOTTERY
				prize_id = o.gift_id.to_s
				prize = Prize.where(:basic_gift_id => prize_id)[0]
				# the type field
				o.type = prize.type == Prize::REAL ? Order::REAL_GOOD : Order::VIRTUAL_GOOD
				# the prize association
				o.prize_id = prize._id
			end
			# the sample association
			o.sample_id = o.user_id
			# the status field
			if o.status == 0 || o.status == 1
				# NeedVerify and Verified
				o.status = Order::WAIT
			elsif o.status == -1
				o.status = Order::REJECT
			elsif o.status == -2
				o.status = Order::REJECT
			elsif o.status == 2
				o.status = Order::HANDLE
			elsif o.status == 3
				o.status = Order::SUCCESS
			elsif o.status == -3
				o.status = Order::FAIL
			end
			o.save
		end
	end

	def self.migrate_point_log
		PointLog.destroy_all
		puts "Migrating orders......"
		RewardLog.all.each_with_index do |rl, index|
			puts index if index%100 == 0
			next if rl.type == 1 # lottery log
			pl = PointLog.new
			# the amount field
			pl.amount = rl.point
			# the reason field
			if rl.cause == 0
				pl.reason = PointLog::ADMIN_OPERATE
			elsif rl.cause == 1
				pl.reason = PointLog::INVITE_USER
			elsif rl.cause == 2
				pl.reason = PointLog::ANSWER
			elsif rl.cause == 3
				pl.reason = PointLog::SPREAD
			elsif rl.cause == 4
				pl.reason = PointLog::REDEEM
			elsif rl.cause == 5
				pl.reason = PointLog::REVOKE
			end
			# the remark field
			pl.remark = rl.cause_desc
			if pl.reason == PointLog::REVOKE
				pl.remark = "订单撤销"
			end
			if pl.reason == PointLog::INVITE_USER
				pl.remark = "邀请样本注册"
			end
			if pl.reason == PointLog::SPREAD
				pl.remark = "邀请样本填写问卷"
			end
			# the survey_id and survey_title field
			if pl.reason == PointLog::ANSWER
				pl.survey_id = rl.filled_survey.try(:_id).to_s
				pl.survey_title = rl.filled_survey.try(:title).to_s
			end
			# the gift name field
			if pl.reason == PointLog::REDEEM
				pl.gift_name = rl.order.try(:gift).try(:name)
			end
			# the user association
			pl.user_id = rl.user_id
			pl.save
		end
	end
end
