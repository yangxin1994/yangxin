class Sample::GiftsController < Sample::SampleController


	def index
	  gc              = Sample::GiftClient.new(session_info)
	  lc              = Sample::LogClient.new(session_info)
	  @sort_type       =  params[:sort_type].present? ? params[:sort_type] : "exchange_count"
	  @hotest_gifts   = gc.get_hoest(params[:page],params[:per_page],@sort_type)  
	  @hotest_gifts   = @hotest_gifts.success ? @hotest_gifts.value : nil 
	  @gift_rank      = gc.get_hoest(1,5,'exchange_count')
	  @gift_rank      = @gift_rank.success ? @gift_rank.value : nil
	  
	  @new_ex_history = lc.get_newest_exchange_history 
	  @new_ex_history = @new_ex_history.success ? @new_ex_history.value : nil
	end

	def get_special_type_data
		gc              = Sample::GiftClient.new(session_info)
		@sort_type       =  params[:status].present? ? params[:status] : "exchange_count"
		@hotest_gifts   = gc.get_hoest(params[:page],params[:per_page],@sort_type)  
	  @hotest_gifts   = @hotest_gifts.success ? @hotest_gifts.value : nil  
	end

	def show
	  user_client = Account::UserClient.new(session_info)

	  @gift_rank      = Sample::GiftClient.new(session_info).get_hoest(1,5,'exchange_count')
	  @gift_rank      = @gift_rank.success ? @gift_rank.value : nil

	  @recerver_info =  Sample::UserClient.new(session_info).get_logistic_address
	  @recerver_info =  @recerver_info.success ? @recerver_info.value : nil
	  @gift = Sample::GiftClient.new(session_info).show(params[:id])
	  @gift.success ? @gift = @gift.value : @gift = nil
	end

end