class Sample::HomesController < Sample::SampleController

	def show
		survey_client   = Sample::SurveyClient.new(session_info)
		@hot_survey     = survey_client.get_hot_survey
		@hot_survey     = @hot_survey.success ? @hot_survey.value :  nil
		@rsl = survey_client.get_recommend_list(1,9,true)
		@rsl = @rsl.success ? @rsl.value : nil
		@public_notices = Sample::PublicNoticeClient.new(session_info).index
		@public_notices = @public_notices.success ? @public_notices.value :  nil

		@hotest_gifts   = Sample::GiftClient.new(session_info).get_hoest(1,8,'exchange_count')
		@hotest_gifts   = @hotest_gifts.success ? @hotest_gifts.value  : nil
		@top_rank_users = Sample::UserClient.new(session_info).get_top_rank_users
		@top_rank_users =  @top_rank_users.success ? @top_rank_users.value : nil
        @fresh_news     = Sample::LogClient.new(session_info).get_fresh_news_list 
        @fresh_news     = @fresh_news.success ? @fresh_news.value : nil

	end


	def demo
	end

	def help
	end
	
end