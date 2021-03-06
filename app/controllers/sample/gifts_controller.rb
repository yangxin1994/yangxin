class Sample::GiftsController < Sample::SampleController

  def index
    params[:per_page] = 12
    sort_type = params[:sort_type].present? ? params[:sort_type]  : 'view_count' 
    hotest_gifts = auto_paginate(Gift.on_shelf.real.desc(sort_type))
    gift_rank = Gift.on_shelf.real.desc(sort_type).limit(5)
    new_ex_history = Log.get_newest_exchange_logs
    @data = {sort_type:sort_type,hotest_gifts:hotest_gifts,gift_rank:gift_rank,new_ex_history:new_ex_history}
    fresh_when(:etag => @data)
    
  end

  def get_special_type_data
    params[:per_page] = 12
    point     =  params[:point].present? ? params[:point]  : nil   
    sort_type = params[:status].present? ? params[:status]  : 'view_count'   
    hotest_gifts = Gift.unscoped.on_shelf.real
    hotest_gifts = hotest_gifts.where(:point.lte => point.to_i)  if point.present?
    hotest_gifts = hotest_gifts.asc("#{sort_type}")  if sort_type.to_s == 'point'
    hotest_gifts = hotest_gifts.desc("#{sort_type}") if sort_type.to_s  != 'point' 
    hotest_gifts = auto_paginate(hotest_gifts)
    @data = {point:point,sort_type:sort_type,hotest_gifts:hotest_gifts}
    fresh_when(:etag => @data)
  end

  def show
    if params[:id] == '522883d5eb0e5b13b9000001'
      # hack 1 yuan phone charge gift
      redirect_to '/gifts' and return
    end
    gift_rank = Gift.on_shelf.real.limit(5)
    gift = Gift.normal.find_by(id: params[:id])
    render_404 if gift.nil?
    gift.inc_view_count
    receiver_info = current_user.nil? ? nil : current_user.affiliated.try(:receiver_info) || {}
    @data = {gift:gift,gift_rank:gift_rank,receiver_info:receiver_info}
    fresh_when(:etag => @data)
  end
end