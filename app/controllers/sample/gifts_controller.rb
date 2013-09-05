# finish migrating
class Sample::GiftsController < Sample::SampleController


	def index
		@sort_type = params[:sort_type].present? ? params[:sort_type]  : 'view_count' 
		params[:per_page] = 12
		@hotest_gifts = Gift.on_shelf.real.desc(@sort_type)
		@hotest_gifts = auto_paginate(@hotest_gifts) do |e|
			e.map { |e| e.info }
		end
		@gift_rank = Gift.on_shelf.real.desc(@sort_type).limit(5).map { |e| e.info }
		@new_ex_history = Log.get_newest_exchange_logs
		fresh_when(:etag => [@hotest_gifts,@gift_rank,@new_ex_history])
	end

	def get_special_type_data
		@point     =  params[:point].present? ? params[:point]  : nil		
		@sort_type = params[:status].present? ? params[:status]  : 'view_count' 	
		params[:per_page] = 12
		@hotest_gifts = Gift.unscoped.on_shelf.real
		if @point.present?
			@hotest_gifts = @hotest_gifts.where(:point.lte => @point.to_i)
		end
		@hotest_gifts = @hotest_gifts.asc("#{@sort_type}")  if @sort_type.to_s == 'point'
		@hotest_gifts = @hotest_gifts.desc("#{@sort_type}") if @sort_type.to_s  != 'point' 

		@hotest_gifts = auto_paginate(@hotest_gifts) do |e|
			e.map { |e| e.info }
		end
		fresh_when(:etag => [@hotest_gifts])
	end



	def show
		@gift_rank = Gift.on_shelf.real.desc(@sort_type).limit(5).map { |e| e.info }
		@gift = Gift.find_by_id(params[:id])
		render_404 if @gift.nil?
		@gift.inc_view_count
		@gift[:photo_src] = @gift.photo.nil? ? Gift::DEFAULT_IMG : @gift.photo.picture_url 
		@receiver_info = current_user.nil? ? nil : current_user.affiliated.try(:receiver_info) || {}
		fresh_when(:etag => [@gift_rank,@gift,@receiver_info])
	end
end