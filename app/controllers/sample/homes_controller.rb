class Sample::HomesController < Sample::SampleController

	def show
		@hot_survey     = Survey.quillme_promote.quillme_hot.opend.first

		surveys = Survey.get_recommends(nil, nil, nil, current_user, nil)
		params[:per_page] = 9
		@rsl = auto_paginate(surveys) do |paginated_surveys|
		  paginated_surveys.map { |e| e.excute_sample_data(current_user) } 
		end

		@public_notices = auto_paginate PublicNotice.opend.desc(:updated_at)

    	@hotest_gifts = Gift.on_shelf.real.desc(:view_count).limit(8).map { |e| e.info }

		@top_rank_users = User.sample.where(:is_block => false).desc(:point).limit(5)
		@top_rank_users = @top_rank_users.map do |user|
			user['nickname'] = user.nickname
			user['spread_count'] = user.spread_count
			user['answer_count'] = user.answers.not_preview.count
			user['avatar_src']= user.avatar? ? user.avatar.picture_url : User::DEFAULT_IMG
			user
		end

        @fresh_news = Log.get_new_logs(5, nil)
        @fresh_news = @fresh_news.each do |log|
          log['avatar'] = log.user.avatar.present? ? log.user.avatar.picture_url : User::DEFAULT_IMG
          log['username'] = log.user.try(:nickname)
          log
        end
	end


	def demo
	end

	def help
	end
	
end