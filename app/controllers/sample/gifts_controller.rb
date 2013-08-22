# finish migrating
class Sample::GiftsController < Sample::SampleController


	def index
	    @sort_type = params[:sort_type].present? ? params[:sort_type]  : 'exchange_count' 
	    params[:per_page] = 12
	    @hotest_gifts = Gift.on_shelf.real.desc(@sort_type)
		@hotest_gifts = auto_paginate(@hotest_gifts) do |e|
			e.map { |e| e.info }
		end
		@gift_rank = Gift.on_shelf.real.desc(@sort_type).limit(5).map { |e| e.info }
		@new_ex_history = Log.get_newest_exchange_logs
	end

	def get_special_type_data
		@sort_type = params[:status].present? ? params[:status]  : 'exchange_count' 
		params[:per_page] = 12
		@hotest_gifts = Gift.on_shelf.real.desc(@sort_type)
		@hotest_gifts = auto_paginate(@hotest_gifts) do |e|
			e.map { |e| e.info }
		end
	end

	def show
		@gift_rank = Gift.on_shelf.real.desc(@sort_type).limit(5).map { |e| e.info }
		@gift = Gift.find_by_id(params[:id])
		render_404 if @gift.nil?
		@gift[:photo_src] = @gift.photo.nil? ? Gift::DEFAULT_IMG : @gift.photo.picture_url 

		@receiver_info = @current_user.nil? ? nil : @current_user.affiliated.try(:receiver_info) || {}

	end
end